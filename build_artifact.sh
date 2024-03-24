#!/usr/bin/env bash

#docker cp temp_container:/tmp/cryptsetup-2.6.1-x86_64-GG.txz ./packages/ &&

docker build -t greycubesgav/slackbuild-clevis:latest . && \
docker create --name temp_container greycubesgav/slackbuild-clevis:latest && \
mkdir -p packages && \
docker cp temp_container:/tmp/clevis-20-x86_64-GG_GG.tgz ./packages/ && \
docker cp temp_container:/tmp/jose-12-x86_64-GG_GG.tgz ./packages/ && \
docker cp temp_container:/tmp/unraid.network.disk.unlock-01-noarch-GG_GG.txz ./packages/ && \
docker rm temp_container && \
md5sum ./packages/*.*
