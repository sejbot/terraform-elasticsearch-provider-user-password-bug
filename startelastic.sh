#!/bin/bash
docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -e "xpack.security.enabled=true" --rm --name es01 docker.elastic.co/elasticsearch/elasticsearch:7.11.2