#!/bin/bash
# apt-get install gnupg
# curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
#    gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg \
#    --dearmor
# echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
# apt-get update
# apt-get install -y mongodb-org
# echo "mongodb-org hold" | dpkg --set-selections
# echo "mongodb-org-database hold" | dpkg --set-selections
# echo "mongodb-org-server hold" | dpkg --set-selections
# echo "mongodb-mongosh hold" | dpkg --set-selections
# echo "mongodb-org-mongos hold" | dpkg --set-selections
# echo "mongodb-org-tools hold" | dpkg --set-selections
pip3 install pymongo
# apt-get install apt-utils -y
# apt-get install libldap2-dev -y
# apt-get install libsasl2-dev -y
# apt-get install jq -y
# apt-get install gcc -y
pip3 install pyopenssl
# pip3 install --upgrade setuptools wheel
# pip3 install python-ldap
pip3 install secrets
# apt-get install mongodb
# which mongod
# service mongod start
# sleep 5

# Start the app in the background
python3 app.py &
PID=$!

# Wait for the app to start up
sleep 2

# Function to clear the db

# Test POST /post and GET /post/id
# This test will exit immediately if the POST /post or GET /post/id fails.
RESPONSE=$(curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}')
key=$(echo $RESPONSE | jq -r '.key')
timestamp=$(echo $RESPONSE | jq -r '.timestamp')
id=$(echo $RESPONSE | jq -r '.id')

TEST=$(curl http://127.0.0.1:5000/post/1)
# GET /post/id test
if [ "$TEST" == "Post with ID: {$id} not found" ]; then
  echo "Get /post/id failed."
  exit 1
else
  echo "Get /post/id passed."
fi

# Check if the response matches the expected output
# POST /post test
EXPECTED={'"id"':$id,'"key"':'"'$key'"','"timestamp"':'"'$timestamp'"'}
if [ "$RESPONSE" != "$EXPECTED" ]; then
  echo "ERROR: POST /post failed"
  echo "Expected: $EXPECTED"
  echo "Actual:   $RESPONSE"
  exit 1
else
  echo "POST /post passed"
fi

# Stop the server
echo "Stopping Flask server..."
kill $PID

# Start the server again
echo "Starting Flask server again..."
flask run &
PID=$!

# Wait for the app to start up
sleep 2

# Testing persistence to see if the post still exists after restarting the server
# This test will exit immediately if the persistence fails.
EXISTS=$(curl http://localhost:5000/post/$id)

if [ "$EXISTS" != "Post with ID: $id not found" ]; then
  echo "Persistence passed."
else
  echo "Persistence failed."
  exit 1
fi

# Testing persistence for a bad request to see if the post still exists
# This test will exit immediately if the persistence fails.
curl http://127.0.0.1:5000/post/fulltext
EXISTS=$(curl http://localhost:5000/post/$id)

if [ "$EXISTS" != "Post with ID: $id not found" ]; then
  echo "Persistence passed."
else
  echo "Persistence failed."
  exit 1
fi

# Testing the delete function by creating 4 more posts and then deleting all 5 of the posts
# This test will exit immediately if the deletion fails.
counter=1
while [ $counter -le 5 ]
do
  RESPONSE=$(curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}')
  key=$(echo $RESPONSE | jq -r '.key')
  id=$(echo $RESPONSE | jq -r '.id')
  curl -X DELETE http://127.0.0.1:5000/post/$id/delete/$key
  EXISTS=$(curl http://localhost:5000/post/$id)
  if [ "$EXISTS" = "Post with ID: $id not found" ]; then
    echo "Delete passed."
  else
    echo "Delete failed."
    exit 1
  fi
  ((counter++))
done

# Test the update function
# This should return "Message updated." Otherwise, the test will exit immediately.
RESPONSE=$(curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}')
Old_post=$(curl http://localhost:5000/post/$id)
key=$(echo $RESPONSE | jq -r '.key')
id=$(echo $RESPONSE | jq -r '.id')
msg=$(echo $Old_post | jq -r '.msg')
curl -X PUT -d '{"msg": "hello I am update"}' http://127.0.0.1:5000/post/$id/update/$key
New_post=$(curl http://localhost:5000/post/$id)
newMsg=$(echo $New_post | jq -r '.msg')

if [ "$msg" == "$newMsg" ]; then
  echo "Message update failed."
  exit 1
else
  echo "Message update passed."
fi

curl -X DELETE http://127.0.0.1:5000/post/$id/delete/$key

# Running the same test as before except commenting out the update function to show that the update will not happen
# This is to show that the update function is actually updating the message
# This should return "Message update failed." Otherwise, the test will exit immediately.

RESPONSE=$(curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}')
Old_post=$(curl http://localhost:5000/post/$id)
key=$(echo $RESPONSE | jq -r '.key')
id=$(echo $RESPONSE | jq -r '.id')
msg=$(echo $Old_post | jq -r '.msg')
# curl -X PUT -d '{"msg": "hello I am update"}' http://127.0.0.1:5000/post/$id/update/$key
New_post=$(curl http://localhost:5000/post/$id)
newMsg=$(echo $New_post | jq -r '.msg')

if [ "$msg" == "$newMsg" ]; then
  echo "Message update failed."
else
  echo "Message update passed."
  exit 1
fi

curl -X DELETE http://127.0.0.1:5000/post/$id/delete/$key

# Testing for fulltext search
# Creating multiple posts and then checking if the fulltext search works on each post
# This will exit immediately if the fulltext search fails
curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}'
curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}'
RESPONSE=$(curl http://127.0.0.1:5000/post/fulltext/"hi%20my%20name%20is%20jason")
counter=0
while [ 1 ]
do
  msg=$(echo $RESPONSE | jq -r '.[0].msg')
  if [ "$msg" != "hi my name is jason" ]; then
    echo "Fulltext search failed."
    exit 1
  fi
  RESPONSE=$(echo "$RESPONSE" | jq 'del(.[0])')
  if [ "$RESPONSE" == [] ]; then
    echo "Fulltext search passed."
    break
  fi
done

# Clean up
DB_NAME="web_forum_database"
mongo <<EOF
use ${DB_NAME}
db.dropDatabase()
EOF

#threaded replies
curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is Atishay"}'
curl http://127.0.0.1:5000/post/1 -X POST -d '{"msg": "I am the reply"}'
RESPONSE=$(curl http://127.0.0.1:5000/post/1)
id=$(echo $RESPONSE | jq -r '.id')
msg=$(echo $RESPONSE | jq -r '.msg')
thread=$(echo $RESPONSE | jq -r '.thread')
timestamp=$(echo $RESPONSE | jq -r '.timestamp')
EXPECTED={'"id"':$id,'"msg"':'"'$msg'"','"thread":[2],"timestamp"':'"'$timestamp'"'}
if [ "$RESPONSE" != "$EXPECTED" ]; then
  echo "ERROR: POST /post/id failed"
  echo "Expected: $EXPECTED"
  echo "Actual:   $RESPONSE"
  exit 1
else
  echo "POST thread /post passed"
fi
curl http://127.0.0.1:5000/post/1 -X POST -d '{"msg": "I am the second reply"}'
RESPONSE=$(curl http://127.0.0.1:5000/post/1)
key=$(echo $RESPONSE | jq -r '.key')
id=$(echo $RESPONSE | jq -r '.id')
msg=$(echo $RESPONSE | jq -r '.msg')
thread=$(echo $RESPONSE | jq -r '.thread')
timestamp=$(echo $RESPONSE | jq -r '.timestamp')
EXPECTED={'"id"':$id,'"msg"':'"'$msg'"','"thread":[2,3],"timestamp"':'"'$timestamp'"'}
if [[ "$RESPONSE" != *"$EXPECTED"* ]]; then
  echo "ERROR: POST /post/id failed"
  echo "Expected: $EXPECTED"
  echo "Actual:   $RESPONSE"
  exit 1
else
  echo "POST thread /post passed"
fi

# Clean up
DB_NAME="web_forum_database"
mongo <<EOF
use ${DB_NAME}
db.dropDatabase()
EOF

#datetime 
curl http://127.0.0.1:5000/post -X POST -d '{"msg": "First Post"}'
RESPONSE1=$(curl http://127.0.0.1:5000/post/1)
key1=$(echo $RESPONSE1 | jq -r '.key')
id1=$(echo $RESPONSE1 | jq -r '.id')
msg1=$(echo $RESPONSE1 | jq -r '.msg')
thread1=$(echo $RESPONSE1 | jq -r '.thread')
timestamp1=$(echo $RESPONSE1 | jq -r '.timestamp')

sleep 1

curl http://127.0.0.1:5000/post -X POST -d '{"msg": "Second Post"}'
RESPONSE2=$(curl http://127.0.0.1:5000/post/2)
key2=$(echo $RESPONSE2 | jq -r '.key')
id2=$(echo $RESPONSE2 | jq -r '.id')
msg2=$(echo $RESPONSE2 | jq -r '.msg')
thread2=$(echo $RESPONSE2 | jq -r '.thread')
timestamp2=$(echo $RESPONSE2 | jq -r '.timestamp')

sleep 1

curl http://127.0.0.1:5000/post -X POST -d '{"msg": "Third Post"}'
RESPONSE3=$(curl http://127.0.0.1:5000/post/3)
key3=$(echo $RESPONSE3 | jq -r '.key')
id3=$(echo $RESPONSE3 | jq -r '.id')
msg3=$(echo $RESPONSE3 | jq -r '.msg')
thread3=$(echo $RESPONSE3 | jq -r '.thread')
timestamp3=$(echo $RESPONSE3 | jq -r '.timestamp')

sleep 1

curl http://127.0.0.1:5000/post -X POST -d '{"msg": "Fourth Post"}'
RESPONSE4=$(curl http://127.0.0.1:5000/post/4)
key4=$(echo $RESPONSE4 | jq -r '.key')
id4=$(echo $RESPONSE4 | jq -r '.id')
msg4=$(echo $RESPONSE4 | jq -r '.msg')
thread4=$(echo $RESPONSE4 | jq -r '.thread')
timestamp4=$(echo $RESPONSE4 | jq -r '.timestamp')

sleep 1

EXPECTED='[{"id":1,"msg":"First Post","thread":[],"timestamp":"'$timestamp1'"},{"id":2,"msg":"Second Post","thread":[],"timestamp":"'$timestamp2'"},{"id":3,"msg":"Third Post","thread":[],"timestamp":"'$timestamp3'"},{"id":4,"msg":"Fourth Post","thread":[],"timestamp":"'$timestamp4'"}]'
RESPONSE=$(curl http://127.0.0.1:5000/post/$timestamp1/$timestamp4)
if [[ "$RESPONSE" != *"$EXPECTED"* ]]; then
  echo "ERROR: POST /post/start/end failed"
  echo "Expected: $EXPECTED"
  echo "Actual:   $RESPONSE"
  exit 1
else
  echo "POST /post passed"
fi

EXPECTED='[{"id":2,"msg":"Second Post","thread":[],"timestamp":"'$timestamp2'"},{"id":3,"msg":"Third Post","thread":[],"timestamp":"'$timestamp3'"},{"id":4,"msg":"Fourth Post","thread":[],"timestamp":"'$timestamp4'"}]'
RESPONSE=$(curl http://127.0.0.1:5000/post/$timestamp2/none)
if [ "$RESPONSE" != "$EXPECTED" ]; then
  echo "ERROR: POST /post/start/end failed"
  echo "Expected: $EXPECTED"
  echo "Actual:   $RESPONSE"
  exit 1
else
  echo "POST /post passed"
fi

EXPECTED='[{"id":1,"msg":"First Post","thread":[],"timestamp":"'$timestamp1'"},{"id":2,"msg":"Second Post","thread":[],"timestamp":"'$timestamp2'"},{"id":3,"msg":"Third Post","thread":[],"timestamp":"'$timestamp3'"}]'
RESPONSE=$(curl http://127.0.0.1:5000/post/none/$timestamp3)
if [[ "$RESPONSE" != *"$EXPECTED"* ]]; then
  echo "ERROR: POST /post/start/end failed"
  echo "Expected: $EXPECTED"
  echo "Actual:   $RESPONSE"
  exit 1
else
  echo "POST /post passed"
fi

echo "fourth"

EXPECTED='Both Start and End cannot be None'
RESPONSE=$(curl http://127.0.0.1:5000/post/none/none)
if [[ "$RESPONSE" != *"$EXPECTED"* ]]; then
  echo "ERROR: POST /post/start/end failed"
  echo "Expected: $EXPECTED"
  echo "Actual:   $RESPONSE"
  exit 1
else
  echo "POST /post passed"
fi

# Clean up
DB_NAME="web_forum_database"
mongo <<EOF
use ${DB_NAME}
db.dropDatabase()
EOF

echo "Yay, all of the tests passed!"

kill $PID
