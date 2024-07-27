#!/bin/sh

# MongoDB installer for Amazon Linux 2
sudo tee -a /etc/yum.repos.d/mongodb-org-7.0.repo > /dev/null <<EOT
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOT
sudo yum install -y mongodb-org
