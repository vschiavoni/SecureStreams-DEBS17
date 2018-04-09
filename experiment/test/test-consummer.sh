#!/usr/bin/env bash

cp ../consummer.lua .

docker run -it --rm -v $(pwd):/root/worker -e "FROM=tcp://router:5556" -e "LOG_LEVEL=trace" -h consummer --name consummer lorel/zmqrxlua-poc:debug
