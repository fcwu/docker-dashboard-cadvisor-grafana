#!/bin/sh -e

while ! curl -fsSL http://grafana:3000/api/dashboards/home 2>/dev/null 1>/dev/null ; do
    sleep 1
done

# create data source
curl -fsSL -H "Content-Type: application/json" \
    -d @/tmp/ds-prometheus.json \
    -XPOST \
    http://grafana:3000/api/datasources

# create default dashboard
curl -fsSL -H "Content-Type: application/json" \
    -d @/tmp/docker-monitoring-with-prometheus_rev2.json \
    -XPOST \
    http://grafana:3000/api/dashboards/db

# set default
curl -fsSL -H "Content-Type: application/json" \
    -d '{"theme":"","homeDashboardId":1,"timezone":""}' -XPUT \
    http://grafana:3000/api/org/preferences
