#!/bin/sh

pull_request_id=$(echo "$GITHUB_REF" | awk -F / '{print $3}')

# use PAT if no github token is set
if [ -z "$1" ]
then
      "$1"="$2"
fi

# fetch pull request branch
result=$(curl -H "Authorization: token $1" -H "Accept: application/vnd.github.v3.full+json" \
 https://api.github.com/repos/"$GITHUB_REPOSITORY"/pulls/"$pull_request_id")
branch=$(echo "$result" | jq '.head.ref')

# create deployment
result2=$(curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/"$GITHUB_REPOSITORY"/deployments \
  -d "{\"ref\":$branch, \"environment\":\"dev\", \"required_contexts\": [], \"auto_merge\": false}")
deployment_id=$(echo "$result2" | jq '.id')

# create deployment status in_progress
curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json,application/vnd.github.ant-man-preview+json,application/vnd.github.flash-preview+json" \
  https://api.github.com/repos/"$GITHUB_REPOSITORY"/deployments/"$deployment_id"/statuses \
  -d "{\"environment\": \"dev\", \"environment_url\": \"http://example.com\", \"state\": \"in_progress\", \"log_url\": \"https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"}"

cd ..

pwd

git clone "https://$2@github.com/$3.git" preview-deployment

cd "preview-deployment" || exit 1

git config user.name "Deploy"
git config user.email "felixoi@users.noreply.github.com"

mkdir -p "$pull_request_id"
if [ -d "$pull_request_id" ]; then
  echo "Updating preview for pull request #$pull_request_id..."
  rm -r ./"$pull_request_id"
  rsync -avz "$GITHUB_WORKSPACE" ./"$pull_request_id" --exclude={'.git','.github'}
else
  echo "Creating preview for pull request #$pull_request_id..."
  rsync -avz "$GITHUB_WORKSPACE" ./"$pull_request_id" --exclude={'.git','.github'}
fi

git add -A
git commit -q -m "Deployed preview for PR #$pull_request_id"
git push -q origin gh-pages

# create deployment status success
curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $1" \
  -H "Accept: application/vnd.github.v3+json,application/vnd.github.ant-man-preview+json" \
  https://api.github.com/repos/"$GITHUB_REPOSITORY"/deployments/"$deployment_id"/statuses \
  -d "{\"environment\": \"dev\", \"environment_url\": \"http://example.com\", \"state\": \"success\", \"log_url\": \"https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"}"
