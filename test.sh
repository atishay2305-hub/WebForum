#!/bin/bash
# echo "├─ pymongo"
pip3 install pymongo
# echo "├─ secrets"
pip3 install secrets

# Start the app in the background
python3 app.py &
PID=$!
echo "$PID"

# Wait for the app to start up
sleep 2

# Test POST /post and GET /post/id
curl http://127.0.0.1:5000/post -X POST -d '{"msg": "hi my name is jason"}'
RESPONSE=$(curl http://localhost:5000/post/1)

# Check if the response matches the expected output
EXPECTED={'"id"':1,'"key"':'"'$(curl http://127.0.0.1:5000/key/1)'"','"msg"':'"hi my name is jason"','"thread"':[],'"timestamp"':'"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"'}
if [[ "$RESPONSE" != *"$EXPECTED"* ]]; then
  echo "ERROR: POST /post failed"
  echo "Expected: $EXPECTED"
  echo "Actual:   $RESPONSE"
  exit 1
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

EXISTS=$(curl http://localhost:5000/post/1)
echo "$EXISTS"

KEY=$(curl http://127.0.0.1:5000/key/1)
curl -X DELETE http://127.0.0.1:5000/post/1/delete/$KEY

kill $PID