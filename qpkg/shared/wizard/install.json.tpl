{
  "api_version": "v1",
  "title": "{{WIZARD_NAME}}",
  "wizard": [
    {
      "title": "{{WIZARD_NETWORK_PAGE}}",
      "schema": {
        "iface": {
          "title": "{{NETWORK_IFACE}}",
          "type": "string",
          "description": "{{NETWORK_IFACE_DESC}}",
          "enum": {{PHYSICAL_NICS}},
          "required": true
        },
        "mode": {
          "type": "string",
          "default": "dhcp",
          "enum": [
            "dhcp",
            "static"
          ]
        },
        "ipv4_addr": {
          "title": "{{NETWORK_ADDR}}",
          "type": "string",
          "pattern": "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
          "description": "{{NETWORK_ADDR_DESC}}",
          "validationMessage": "{{NETWORK_ADDR_MSG}}",
          "required": true
        },
        "subnet": {
          "title": "{{NETWORK_SUBNET}}",
          "type": "string",
          "pattern": "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\/([0-9]|[1-2][0-9]|3[0-2]))$",
          "description": "{{NETWORK_SUBNET_DESC}}",
          "validationMessage": "{{NETWORK_SUBNET_MSG}}",
          "required": true
        },
        "gateway": {
          "title": "{{NETWORK_DEF_GATEWAY}}",
          "type": "string",
          "pattern": "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
          "description": "{{NETWORK_DEF_GATEWAY_DESC}}",
          "validationMessage": "{{NETWORK_DEF_GATEWAY_MSG}}",
          "required": true
        }
      },
      "form": [
        {
          "key": "iface",
          "type": "select",
          "titleMap": {{PHYSICAL_NIC_NAME_TITLE_DICT}}
        },
        {
          "key": "mode",
          "type": "radio",
          "notitle": true,
          "value": "dhcp",
          "onChange": "model.ipv4_addr = ''; model.subnet = ''; model.gateway = ''",
          "label": "{{NETWORK_DHCP_MODE_LABEL}}"
        },
        {
          "key": "mode",
          "type": "radio",
          "notitle": true,
          "value": "static",
          "label": "{{NETWORK_STATIC_MODE_LABEL}}"
        },
        {
          "key": "ipv4_addr",
          "placeholder": "192.168.1.2",
          "condition": "model.mode == 'static'"
        },
        {
          "key": "subnet",
          "placeholder": "192.168.1.0/24",
          "condition": "model.mode == 'static'"
        },
        {
          "key": "gateway",
          "placeholder": "192.168.1.1",
          "condition": "model.mode == 'static'"
        }
      ]
    }
  ],
  "binding": {
    "type": "yaml",
    "file": "docker-compose.yml",
    "data": {
      "iface": "networks.fronttier.ipam.driver_opts.iface",
      "ipv4_addr": "services.grafana.networks.fronttier.ipv4_address",
      "subnet": "networks.fronttier.ipam.config[0].subnet",
      "gateway": "networks.fronttier.ipam.config[0].gateway"
    },
    "template": ["*.tpl"]
  }
}
