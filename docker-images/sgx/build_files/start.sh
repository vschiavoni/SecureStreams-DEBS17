#!/bin/bash

LUASGX=./luasgx
SRC_DIR=/root/worker
SGX=/dev/isgx


if [[ ! (-c $SGX) ]]; then
    echo "Device $SGX not found"
    echo "Use 'docker run' flag --device: --device=$SGX"
    exit 0
fi

if [[ -z $1 ]]; then
    echo "No file provided - you have to pass the filename of the LUA code as argument"
    exit 1
fi

if [[ ! (-e $SRC_DIR) ]]; then
    echo "No volume mounted - you have to mount a volume including the LUA code you want to embed in the container"
    echo "Use 'docker run' flag -v: -v /my/lua/src:$SRC_DIR"
    exit 0
fi

if [[ ! (-e $SRC_DIR/$1) ]]; then
    echo "File $SRC_DIR/$1 not found"
    exit 0
fi


echo "Run AESM service"
/opt/intel/sgxpsw/aesm/aesm_service &


echo "Wait 1s for AESM service to be up"
sleep 1

echo "Link source files from $SRC_DIR into $(pwd)"
ln -s $SRC_DIR/* .

echo "$(pwd) content"
ls -al .

echo "Run LUA_PATH='$SRC_DIR/?.lua;;' $LUASGX $SRC_DIR/$1"
LUA_PATH="$SRC_DIR/?.lua;;" $LUASGX $SRC_DIR/$1


#echo "Run bash for debugging"
#bash
