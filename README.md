# SecureStreams

This repository contains a proof of concept about distributed MapReduce written
in Lua and using reactive streams pattern and communicating by ØMQ.


## Requirements

- docker
- docker-compose


## Build the docker image

From the directory `docker-image/` run

```bash
$ ./build.sh
```


## Run XP

From the directory `experiment/test/` run

```bash
$ ./run.sh
```
