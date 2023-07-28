#!/bin/bash
# set the offline token and checksum parameters
offline_token="eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJhZDUyMjdhMy1iY2ZkLTRjZjAtYTdiNi0zOTk4MzVhMDg1NjYifQ.eyJpYXQiOjE2OTA1MDI2NTEsImp0aSI6IjA3MzBmNTFiLWUwYjAtNDdkNS04OWNmLWNhMWFlODc3MDMxYSIsImlzcyI6Imh0dHBzOi8vc3NvLnJlZGhhdC5jb20vYXV0aC9yZWFsbXMvcmVkaGF0LWV4dGVybmFsIiwiYXVkIjoiaHR0cHM6Ly9zc28ucmVkaGF0LmNvbS9hdXRoL3JlYWxtcy9yZWRoYXQtZXh0ZXJuYWwiLCJzdWIiOiJmOjUyOGQ3NmZmLWY3MDgtNDNlZC04Y2Q1LWZlMTZmNGZlMGNlNjppdGd1eWVyaWMiLCJ0eXAiOiJPZmZsaW5lIiwiYXpwIjoicmhzbS1hcGkiLCJzZXNzaW9uX3N0YXRlIjoiYTBiYTE5MjktZGE5ZC00YWY5LTk5NGItYTRhNTVmMzE4YWE5Iiwic2NvcGUiOiJvZmZsaW5lX2FjY2VzcyIsInNpZCI6ImEwYmExOTI5LWRhOWQtNGFmOS05OTRiLWE0YTU1ZjMxOGFhOSJ9.48NkiOuj4ytSRMx7laHNDS9uqMIuNUjWFN5-PHIxYPQ"
checksum=$1

# get an access token
access_token=$(curl https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token -d grant_type=refresh_token -d client_id=rhsm-api -d refresh_token=$offline_token | jq -r '.access_token')

# get the filename and download url
image=$(curl -H "Authorization: Bearer $access_token" "https://api.access.redhat.com/management/v1/images/$checksum/download")
filename=$(echo $image | jq -r .body.filename)
url=$(echo $image | jq -r .body.href)

# download the file
curl $url -o $filename
