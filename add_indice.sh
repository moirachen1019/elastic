#! /usr/bin/env bash

# curl -X PUT "http://angel.ed.de:9200/my_index4?pretty" -H 'Content-Type: application/json' -d'
# {
#     "mappings": {
#         "_doc": {
#             "dynamic": "strict",
#             "properties": {
#                 "field1": { "type": "keyword" },
#                 "field2": { "type": "keyword" }
#             }
#         }
#     }
# }
# '

# curl -X POST "http://angel.ed.de:9200/my_index1/_doc?pretty" -H "Content-Type: application/json" -d '{
#   "field1": "hey",
#   "field2": "yo"
# }'

curl -X POST "http://angel.ed.de:9200/*/_delete_by_query?pretty" -H "Content-Type: application/json" -d '{
  "query": {
    "match_all": {}
  }
}'