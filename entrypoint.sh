#!/bin/bash

result=$(curl -H "Authorization: token $1" -H "Accept: application/vnd.github.v3.full+json" \
 https://api.github.com/repos/$3/pulls/$4)

echo "..."
echo "$result"
echo "..."

jq '.head.ref' <<< "$result"
