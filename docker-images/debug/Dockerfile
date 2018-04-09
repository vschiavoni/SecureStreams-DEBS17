FROM ubuntu:16.04
MAINTAINER aurelien.havet@unine.ch
ENV PACKAGES git gcc g++ make cmake liblua5.3-dev wget
WORKDIR /root

ADD build_files/timer.c /root/timer.c
ADD build_files/sgx_encryptor.c sgx_encryptor.c
ADD build_files/crypto.cpp crypto.cpp
ADD build_files/crypto.h crypto.h

RUN apt-get update && \
  apt-get install -y $PACKAGES libcrypto++-dev liblua5.3-0 libzmq5-dev lua5.3 && \
  git clone https://github.com/Lorel/lzmq.git && \
  cd lzmq && \
  mkdir cmake-make && \
  cd cmake-make && \
  cmake .. && \
  make install && \
  mkdir -p /usr/local/lib/lua/5.3/ && \
  mv /usr/local/lib/lua/lzmq /usr/local/lib/lua/5.3/lzmq && \
  mv /usr/local/lib/lua/lzmq.so /usr/local/lib/lua/5.3/lzmq.so && \
  rm -rf /root/lzmq/ && \
  cd /root && \
  git clone https://github.com/cloudwu/lua-cjson.git && \
  cd lua-cjson && \
  make install LUA_INCLUDE_DIR=/usr/include/lua5.3 LUA_VERSION=5.3 && \
  rm -rf /root/lua-cjson && \
  cd /root && \
  git clone https://github.com/Lorel/luacsv.git && \
  gcc -fPIC -I/usr/include/lua5.3/ -shared -O3 /root/luacsv/csv.c -o /usr/local/lib/lua/5.3/csv.so && \
  rm -rf /root/luacsv/ && \
  wget -O /usr/local/lib/lua/5.3/rx.lua https://raw.githubusercontent.com/bjornbytes/RxLua/master/rx.lua && \
  wget -O /usr/local/lib/lua/5.3/log.lua https://raw.githubusercontent.com/Lorel/log.lua/master/log.lua && \
  gcc -fPIC -I/usr/include/lua5.3/ -shared -O3 /root/timer.c -o /usr/local/lib/lua/5.3/timer.so && \
  g++ -fPIC -I. -I/usr/include/lua5.3/ -shared -O3 /root/sgx_encryptor.c /root/crypto.cpp -o /usr/local/lib/lua/5.3/sgx_encryptor.so -lcryptopp && \
  rm -f /root/timer.c /root/sgx_encryptor.c /root/crypto.cpp /root/crypto.h && \
  cd /root && \
  git clone https://github.com/Lorel/luadec && \
  cd luadec && \
  git submodule update --init lua-5.3 && \
  cd lua-5.3 && \
  make linux && \
  cd ../luadec && \
  make LUAVER=5.3 && \
  mv luadec /usr/bin && \
  rm -rfv /root/luadec && \
  apt-get -y remove --auto-remove $PACKAGES && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update && apt-get install -y inetutils-ping net-tools nmap netcat traceroute

RUN ln -s /usr/bin/lua5.3 /usr/bin/lua

ADD build_files/zmq-rx.lua /usr/local/lib/lua/5.3/
ADD build_files/sgx.lua /usr/local/lib/lua/5.3/
ADD build_files/sgx-rx.lua /usr/local/lib/lua/5.3/
RUN mkdir /root/worker

WORKDIR /root/worker
ENTRYPOINT ["lua"]
