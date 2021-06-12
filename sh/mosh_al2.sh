#!/bin/sh

# Mosh installer for Amazon Linux 2
sudo yum -y install autoconf automake gcc gcc-c++ make boost-devel zlib-devel ncurses-devel protobuf-devel openssl-devel
cd /usr/local/src
sudo wget http://mosh.mit.edu/mosh-1.2.4.tar.gz
sudo tar xvf mosh-1.2.4.tar.gz
cd mosh-1.2.4
sudo ./autogen.sh
sudo ./configure
sudo make
sudo make install
echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
echo "export LANG=en_US.UTF-8" >> ~/.bashrc
echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc
source ~/.bashrc
echo "Don't forget to open UDP 60000-61000"

