version: '2'

networks:
  backtier:
    driver: bridge
    ipam:
      driver: default
  fronttier:
    driver: qnet
    ipam:
      driver: qnet
      driver_opts:
        iface: DEFAULT_NIC

services:
  prometheus:
    image: prom/prometheus
    restart: always
    volumes:
      - ${PWD}/data/prometheus/:/etc/prometheus/
      - ${PWD}/data/prometheus-data/:/prometheus/
    command:
      - '-config.file=/etc/prometheus/prometheus.yml'
      - '-storage.local.path=/prometheus'
    depends_on:
      - cadvisor
    networks:
      - backtier
  
  node-exporter:
    image: prom/node-exporter
    networks:
      - backtier
  
  cadvisor:
    image: google/cadvisor
    restart: always
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    expose:
      - 8080
    networks:
      - backtier
  
  grafana:
    image: grafana/grafana
    restart: always
    depends_on:
      - prometheus
    volumes:
      - ${PWD}/data/grafana:/var/lib/grafana
    env_file:
      - ${PWD}/config.monitoring
    networks:
      - fronttier
      - backtier

  grafana-init:
    image: dorowu/prometheus-grafana-init:v1
    depends_on:
      - grafana
    networks:
      - backtier
    restart: on-failure
