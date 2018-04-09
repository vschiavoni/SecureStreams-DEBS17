#!/usr/bin/env bash

cp ../router.lua .

docker run -it --rm -v $(pwd):/root/worker -e "FROM=tcp://*:5555" -e "TO=tcp://*:5556" -e "LOG_LEVEL=trace" -h router --name router lorel/zmqrxlua-poc:debug
