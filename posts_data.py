from datetime import datetime
from pymongo import MongoClient
from threading import Lock
import secrets

# Define the connection URL and database name
url = "mongodb://localhost:27017/"
db_name = "web_forum_database"

# Create a MongoClient object and access the database
client = MongoClient(url)
db = client[db_name]

# Define a lock object to manage access to global state
lock = Lock()


def create_post(msg):
    if not isinstance(msg, str) or msg is None:
        return "Post content should be of type string", 400

    # Generate a new UUID for the post
    post_id = len(list(db["posts_collection"].find()))

    # Get the current time
    timestamp = datetime.now()

    # Generate a random key
    key = secrets.token_hex(16)

    # Create a new post object with the UUID, message, and timestamp
    new_post = {
        "id": post_id,
        "msg": msg,
        "key": key,
        "timestamp": timestamp,
        "thread": []
    }

    # Insert the new post object into the database
    with lock:
        posts_collection = db["posts_collection"]
        result = posts_collection.insert_one(new_post)

    return result


def get_posts():
    # Get all posts from the database
    with lock:
        posts_collection = db["posts_collection"]
        posts_cursor = posts_collection.find()

    # Convert posts from a cursor to a list
    posts_list = []
    for post in posts_cursor:
        posts_list.append(post)

    return posts_list


def get_post_by_id(id):
    # Get a post from the database by ID
    with lock:
        posts_collection = db["posts_collection"]
        post = posts_collection.find_one({"id": id})

    if post is None:
        return f"Post with ID: {id} not found", 404

    return post


def delete_post(id, key):
    # Find the post with the given ID
    with lock:
        posts_collection = db["posts_collection"]
        post = posts_collection.find_one({"id": id})

    # Check if the post exists
    if post is None:
        return "Post not found", 404

    # Check if the key matches
    if post["key"] != key:
        return "Forbidden", 403

    # Delete the post
    with lock:
        result = posts_collection.delete_one({"id": id})

    # Check if the deletion was successful
    if result.deleted_count == 0:
        return "Error deleting post", 500

    return f"Post with ID: {id} deleted successfully", 200
