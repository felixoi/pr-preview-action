#!/bin/sh

result=$(curl -H "Authorization: token $1" -H "Accept: application/vnd.github.v3.full+json" \
 https://api.github.com/repos/"$3"/pulls/"$5")

branch=$(echo "$result" | jq '.head.ref')

result2=$(curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/"$3"/deployments \
  -d "{'ref':'$branch', environment: 'dev', required_contexts: []}")

deployment_id=$(echo "$result2" | jq '.id')

curl \
  -X POST \
  -H "Content-Type: application/json,application/vnd.github.ant-man-preview+json,application/vnd.github.flash-preview+json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/"$3"/deployments/"$deployment_id"/statuses \
  -d "{environment: 'dev', environment_url: 'http://example.com', state: 'in_progress', log_url: 'https://github.com/$3/actions/runs/$6'}"

curl \
  -X POST \
  -H "Content-Type: application/json,application/vnd.github.ant-man-preview+json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/"$3"/deployments/"$deployment_id"/statuses \
  -d "{environment: 'dev', environment_url: 'http://example.com', state: 'success', log_url: 'https://github.com/$3/actions/runs/$6'}"
