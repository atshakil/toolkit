#!/bin/sh

# MongoDB installer for Amazon Linux 2
sudo tee -a /etc/yum.repos.d/mongodb-org-4.4.repo > /dev/null <<EOT
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOT
sudo yum install -y mongodb-org

