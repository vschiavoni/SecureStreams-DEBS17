#!/usr/bin/env bash

IMAGE=lorel/zmqrxlua:sgx

cp -f ../../experiment/zmq-rx.lua build_files/zmq-rx.lua
cp -f ../../experiment/sgx.lua build_files/sgx.lua
cp -f ../../experiment/sgx-rx.lua build_files/sgx-rx.lua
docker build -t $IMAGE .
