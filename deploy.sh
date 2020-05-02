#!/bin/bash

docker-compose build
docker-compose down
docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d
