#!/bin/sh

result=$(curl -H "Authorization: token $1" -H "Accept: application/vnd.github.v3.full+json" \
 https://api.github.com/repos/"$GITHUB_REPOSITORY"/pulls/"$4")

branch=$(echo "$result" | jq '.head.ref')

result2=$(curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/"$GITHUB_REPOSITORY"/deployments \
  -d "{\"ref\":$branch, \"environment\":\"dev\", \"required_contexts\": [], \"auto_merge\": false}")

deployment_id=$(echo "$result2" | jq '.id')

curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json,application/vnd.github.ant-man-preview+json,application/vnd.github.flash-preview+json" \
  https://api.github.com/repos/"$GITHUB_REPOSITORY"/deployments/"$deployment_id"/statuses \
  -d "{\"environment\": \"dev\", \"environment_url\": \"http://example.com\", \"state\": \"in_progress\", \"log_url\": \"https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"}"

curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json,application/vnd.github.ant-man-preview+json" \
  https://api.github.com/repos/"$GITHUB_REPOSITORY"/deployments/"$deployment_id"/statuses \
  -d "{\"environment\": \"dev\", \"environment_url\": \"http://example.com\", \"state\": \"success\", \"log_url\": \"https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"}"

pwd
ls -la
