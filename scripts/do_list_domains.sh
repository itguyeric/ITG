#!/bin/sh

ACCESS_TOKEN=e880755d5ca30aade5863790e4f90338272ebaf6d308146b8b5d0d7c7e36191e
DOMAIN=itguyeric.com

response=$(curl \
  --silent \
  -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
   "https://api.digitalocean.com/v2/domains/$DOMAIN/records")

echo $response | grep -Eo '"id":\d*|"type":"\w*"|"data":".*?"'
