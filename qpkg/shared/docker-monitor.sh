#!/bin/sh
QPKG_CONF=/etc/config/qpkg.conf
QPKG_NAME=docker-monitor
QPKG_DISPLAY_NAME=$(/sbin/getcfg $QPKG_NAME Display_Name -f $QPKG_CONF)
QPKG_DIR=$(/sbin/getcfg $QPKG_NAME Install_Path -f $QPKG_CONF)
CONTAINER_STATION_DIR=$(/sbin/getcfg container-station Install_Path -f $QPKG_CONF)
DOCKER=$(/sbin/getcfg $QPKG_NAME Docker_Cmd -d "system-docker" -f $QPKG_CONF)

# source qpkg/dqpkg functions
QTS_LOG_TAG="$QPKG_DISPLAY_NAME"
. $CONTAINER_STATION_DIR/script/qpkg-functions
. $CONTAINER_STATION_DIR/script/dqpkg-functions

# main
echo 'start ' `date` >> /tmp/a.log
echo "  $1" >> /tmp/a.log
case "$1" in
  start)
    if ! qts_qpkg_is_enabled $QPKG_NAME; then
        qts_error_exit "$QPKG_DISPLAY_NAME is disabled."
    fi
    echo 1 >> /tmp/a.log
    wait_qcs_ready
    echo 2 >> /tmp/a.log
    qbus_cmd start
    complete_action "configure installing installed starting running stopping stopped" 120
    ;;

  stop)
    qbus_cmd stop
    complete_action "removed stopped" 30
    sh ${QPKG_DIR}/delete-iptables-rules.sh 2>/dev/null
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  remove)
    qbus_cmd remove
    complete_action "removed" 60
    ;;

  pre-configure)
    ./pre-configure.py
    ;;

  check-health)
    web_container_id=`sh compose ps -q grafana`
    ipv4addr=`$DOCKER inspect --format='{{.NetworkSettings.Networks.dockermonitor_fronttier.IPAddress}}' $web_container_id`
    ipv4addr_internal=`$DOCKER inspect --format='{{.NetworkSettings.Networks.dockermonitor_backtier.IPAddress}}' $web_container_id`
    if curl -sq http://${ipv4addr}:3000/ > /dev/null; then
        sed "s/{{IPV4ADDR}}/${ipv4addr}/" docker-monitor.apache.conf.tpl > docker-monitor.apache.conf
        if ! iptables -t nat -S POSTROUTING | grep "${ipv4addr_internal}/16 -j MASQUERADE"; then
            iptables -t nat -A POSTROUTING -s ${ipv4addr_internal}/16 -j MASQUERADE
            echo "iptables -t nat -D POSTROUTING -s ${ipv4addr_internal}/16 -j MASQUERADE" > ${QPKG_DIR}/delete-iptables-rules.sh
        fi
        exit 0
    fi
    exit 1
    ;;

  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac

exit 0
