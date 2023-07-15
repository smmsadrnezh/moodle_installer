#!/bin/bash

echo 'nameserver 178.22.122.100' >> /etc/resolv.conf
echo 'nameserver 185.51.200.2' >> /etc/resolv.conf
docker pull bitnami/moodle:latest
docker stop moodle
docker rm moodle
cd /root/docker/moodle/
docker-compose up -d
