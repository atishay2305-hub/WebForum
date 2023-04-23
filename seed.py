from pymongo import MongoClient
from pprint import pprint
import posts_data

url = "mongodb://localhost:27017/"
db_name = "web_forum_database"

client = MongoClient(url)
client.drop_database(db_name)

posts_data.create_post("test post 1, hello world 2")
posts_data.create_post("test post 2, foobarfoobarfoobarfoobar 2.")
posts_data.create_post("test post 3, \nthis is my last test post 2.")

post1 = posts_data.get_post_by_id(1)
post2 = posts_data.get_post_by_id(2)
post0 = posts_data.get_post_by_id(0)
post3 = posts_data.get_post_by_id(3)

pprint(post0)
pprint(post1)
pprint(post2)

print("--------------------------")

pprint(post3)

print("--------------------------")

print(posts_data.delete_post(1, post1['key']))

print("--------------------------")

pprint(posts_data.get_posts())
