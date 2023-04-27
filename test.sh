#!/bin/bash
# echo "├─ pymongo"
pip3 install pymongo
# echo "├─ secrets"
pip3 install secrets

# Start the app in the background
python3 app.py &
PID=$!

# Wait for the app to start up
sleep 2

# Test POST /post and GET /post/id
curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}'
RESPONSE=$(curl http://localhost:5000/post/1)
key=$(echo $RESPONSE | jq -r '.key')
timestamp=$(echo $RESPONSE | jq -r '.timestamp')

if [ "$RESPONSE" != "Post with ID: 1 not found" ]; then
  echo "Get /post/id passed."
else
  echo "Get /post/id failed."
fi

# Check if the response matches the expected output
EXPECTED={'"id"':1,'"key"':'"'$key'"','"msg"':'"hi my name is jason"','"thread"':[],'"timestamp"':'"'$timestamp'"'}
if [[ "$RESPONSE" != *"$EXPECTED"* ]]; then
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
EXISTS=$(curl http://localhost:5000/post/1)
echo "$EXISTS"

if [ "$EXISTS" != "Post with ID: 1 not found" ]; then
  echo "Persistence passed."
else
  echo "Persistence failed."
fi

# Testing persistence for a bad request to see if the post still exists
curl asjknfadj
EXISTS=$(curl http://localhost:5000/post/1)
echo "$EXISTS"

if [ "$EXISTS" != "Post with ID: 1 not found" ]; then
  echo "Persistence passed."
else
  echo "Persistence failed."
fi

# Testing the delete function
counter=2
while [ $counter -le 5 ]
do
  curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}'
  ((counter++))
done

counter=1
while [ $counter -le 5 ]
do
  RESPONSE=$(curl http://localhost:5000/post/$counter)
  key=$(echo $RESPONSE | jq -r '.key')
  curl -X DELETE http://127.0.0.1:5000/post/$counter/delete/$key
  EXISTS=$(curl http://localhost:5000/post/$counter)
  if [ "$EXISTS" = "Post with ID: $counter not found" ]; then
    echo "Delete passed."
  else
    echo "Delete failed."
  fi
  ((counter++))
done

kill $PID