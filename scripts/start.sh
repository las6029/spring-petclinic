#!/bin/bash
cd /home/ubuntu/scripts
# sudo docker-compose up -d --build
docker compose pull
docker compose up -d --build
