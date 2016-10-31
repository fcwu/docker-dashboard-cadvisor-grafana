#!/usr/bin/env python
from glob import glob
from os.path import basename as pbasename
import json
import subprocess as sp
import re
from os import readlink


def get_physical_nics():
    options = []
    bonds = {}
    for p in glob('/sys/class/net/eth*'):
        options.append(pbasename(p))
    options = set(options)
    for p in glob('/sys/class/net/bond*'):
        eths = []
        for psub in glob(p + '/lower_*') + glob(p + '/brif/*'):
            psub = pbasename(psub)
            if psub.startswith('lower_'):
                psub = psub[6:]
            if not psub.startswith('eth'):
                continue
            eths.append(psub)
            options -= {psub}
        if len(eths) > 0:
            options.add('+'.join(eths))
            bonds[pbasename(p)] = '+'.join(eths)
    options = list(options)
    options.sort()
    return options


def get_nic_parent(nic):
    bridge_path = glob('/sys/class/net/' + nic + '/brport/bridge')
    if len(bridge_path) <= 0:
        return None
    bridge_name = pbasename(readlink(bridge_path[0]))
    return bridge_name


def get_nic_ipv4(nic):
    out = sp.check_output(['ip', 'a', 's', nic])
    mobj = re.match(r'.*inet ([0-9.]+).*', out.replace('\n', ' '))
    if mobj is not None:
        return mobj.group(1)
    return None


def get_nic_title(nic):
    # <type> <#> ({Virtual Switch X}, {IP}, {Disconnected})
    # eth --> Adapter
    # bond --> Bonding Adapter
    title = nic
    attributes = []
    if nic.startswith('eth'):
        title = 'Adapter ' + str(int(nic[3:]) + 1)
    elif nic.startswith('bond'):
        title = 'Bonding Adapter ' + str(int(nic[4:]) + 1)
    try:
        ## link status
        #if out_nic.find('LOWER_UP') < 0:
        #    attributes.append('Disconnected')
        # ipv4 address
        parent_bridge = get_nic_parent(nic)
        ipv4addr = get_nic_ipv4(parent_bridge or nic)
        if ipv4addr is not None:
            attributes.append(ipv4addr)
    except sp.CalledProcessError:
        pass
    if len(attributes) > 0:
        title = '{} ({})'.format(title, ', '.join(attributes))
    return title


def get_default_routing_nic():
    for line in sp.check_output(['ip', 'route']).split('\n'):
        if not line.startswith('default '):
            continue
        fields = line.split()
        default_gw = fields[4]
        return default_gw
    return None


def get_first_nic_having_ipaddr():
    for nic in get_physical_nics():
        parent_bridge = get_nic_parent(nic)
        ipv4addr = get_nic_ipv4(parent_bridge or nic)
        if ipv4addr is not None:
            return nic
    return None


def main():
    # load
    with open('wizard/install.json.tpl') as f:
        installjson_str = f.read()
    with open('docker-compose.yml.tpl') as f:
        compose_str = f.read()

    # nics
    nics = get_physical_nics()
    installjson_str = installjson_str.replace(
        '{{PHYSICAL_NICS}}', json.dumps(nics)
    )

    # default nic
    default_nic = get_default_routing_nic()
    if default_nic not in nics:
        default_nic = get_first_nic_having_ipaddr()
    if default_nic not in nics:
        default_nic = nics[0]
    compose_str = compose_str.replace(
        'DEFAULT_NIC', default_nic
    )

    # title
    nics_title_dict = {nic: get_nic_title(nic) for nic in nics}
    installjson_str = installjson_str.replace(
        '{{PHYSICAL_NIC_NAME_TITLE_DICT}}', json.dumps(nics_title_dict,
                                                       sort_keys=True)
    )

    # write back
    with open('wizard/install.json', 'w+') as f:
        f.write(installjson_str)
    with open('docker-compose.yml', 'w+') as f:
        f.write(compose_str)


if __name__ == '__main__':
    main()
