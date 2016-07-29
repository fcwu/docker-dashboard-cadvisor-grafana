FROM alpine:3.4

RUN apk update && apk add curl
ADD init.sh /init.sh
ADD docker-monitoring-with-prometheus_rev2.json ds-prometheus.json /tmp/
CMD ["/init.sh"]
