#!/usr/bin/env bash

cp ../producer.lua .

docker run -it --rm -v $(pwd):/root/worker -e "TO=tcp://router:5555" -e "LOG_LEVEL=trace" -h producer --name producer lorel/zmqrxlua-poc:debug
