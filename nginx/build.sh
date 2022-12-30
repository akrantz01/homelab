#!/bin/bash

set -eux

docker build -t nginx-deb:latest .
docker create --name nginx-deb nginx-deb:latest
docker cp nginx-deb:/nginx_amd64.deb .
docker container rm nginx-deb
