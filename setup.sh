#!/bin/bash

echo "├─ Installing dependencies"
apt-get update
pip3 install pymongo
apt-get install apt-utils -y
apt-get install libldap2-dev -y
apt-get install libsasl2-dev -y
pip3 install pyopenssl
pip3 install --upgrade setuptools wheel
pip3 install python-ldap
pip3 install secrets

echo "└─ Dependencies successfully installed!"
