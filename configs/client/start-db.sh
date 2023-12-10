#!/bin/bash

mkdir -p /mnt/rbd/postgres/pgadmin
chown -R 5050:5050 /mnt/rbd/postgres/pgadmin
apt update && apt install -y docker-compose

docker-compose up -d
