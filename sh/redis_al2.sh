#!/bin/sh

# Redis installer for Amazon Linux 2
sudo yum -y install wget autoconf automake gcc gcc-c++ make boost-devel zlib-devel ncurses-devel protobuf-devel openssl-devel
wget https://download.redis.io/redis-stable.tar.gz
tar xvf redis-stable.tar.gz
cd redis-stable
make BUILD_TLS=yes
sudo make install
