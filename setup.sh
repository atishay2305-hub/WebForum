#!/bin/bash

echo "├─ Installing dependencies"
# echo "├─ flask"
# pip install flask
echo "├─ pymongo"
pip install pymongo
echo "├─ secrets"
pip install secrets
# idk if we should use pip or pip3, or just do both
# pip3 install flask
# pip3 install pymongo
# pip3 install secrets

echo "└─ Dependencies successfully installed!"
