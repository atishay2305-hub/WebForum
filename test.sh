#!/bin/sh

python app.py 

# sleep 5


set -e # exit immediately if newman complains
trap 'kill $PID' EXIT # kill the server on exit

./run.sh &
PID=$! # record the PID

# # valid message
curl -X POST -H "Content-Type: application/json" -d '{"msg": "test message."}' http://127.0.0.1:5000/post

# #invalid message (not a string)
curl -X POST -H "Content-Type: application/json" -d '{"msg": 123}' http://127.0.0.1:5000/post

# #get
curl http://localhost:5000/post/1

#update
curl -X PUT -d '{"msg": "hello I am update"}' http://127.0.0.1:5000/post/id/update/key

python seed.py -m unittest discover -s . -p "app.py"



# newman run forum_multiple_posts.postman_collection.json -e env.json # use the env file
# newman run forum_post_read_delete.postman_collection.json -n 50 # 50 iterations