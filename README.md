# SecureStreams

This repository contains the source code of SecureStreams.
If you use this code, please cite:

```
@inproceedings{Havet:2017:SRM:3093742.3093927,
 author = {Havet, Aur{\'e}lien and Pires, Rafael and Felber, Pascal and Pasin, Marcelo and Rouvoy, Romain and Schiavoni, Valerio},
 title = {SecureStreams: A Reactive Middleware Framework for Secure Data Stream Processing},
 booktitle = {Proceedings of the 11th ACM International Conference on Distributed and Event-based Systems},
 series = {DEBS '17},
 year = {2017},
 isbn = {978-1-4503-5065-5},
 location = {Barcelona, Spain},
 pages = {124--133},
 numpages = {10},
 url = {http://doi.acm.org/10.1145/3093742.3093927},
 doi = {10.1145/3093742.3093927},
 acmid = {3093927},
 publisher = {ACM},
 address = {New York, NY, USA},
 keywords = {Middleware, SGX, security, stream processing},
} 
````

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
