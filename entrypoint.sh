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

cd "$GITHUB_WORKSPACE/" || exit 1
cd ..

git clone "https://$2@github.com/$3.git" preview-deployment

cd "preview-deployment" || exit 1
git config user.name "felixoi"
git config user.email "felixoi@users.noreply.github.com"

mkdir -p "$pull_request_id"
if [ -d "$pull_request_id" ]; then
  echo "Updating preview for pull request #$pull_request_id..."
  rm -r ./"$pull_request_id"
  rsync -avz "$GITHUB_WORKSPACE/" "$pull_request_id" --exclude='.git' --exclude '.github'
else
  echo "Creating preview for pull request #$pull_request_id..."
  rsync -avz "$GITHUB_WORKSPACE/" "$pull_request_id" --exclude='.git' --exclude '.github'
fi

if [ -z "$(git status --porcelain)" ]
then
  echo "Preview for PR #$pull_request_id is already up-to-date!"
else
  # create deployment
  result2=$(curl \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: token $1" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/"$GITHUB_REPOSITORY"/deployments \
    -d "{\"ref\":$branch, \"environment\":\"$4/$pull_request_id\", \"required_contexts\": [], \"auto_merge\": false}")
  deployment_id=$(echo "$result2" | jq '.id')

  # create deployment status in_progress
  curl \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: token $1" \
    -H "Accept: application/vnd.github.v3+json,application/vnd.github.ant-man-preview+json,application/vnd.github.flash-preview+json" \
    https://api.github.com/repos/"$GITHUB_REPOSITORY"/deployments/"$deployment_id"/statuses \
    -d "{\"environment\": \"$pull_request_id\", \"environment_url\": \"$4/$pull_request_id\", \"state\": \"in_progress\", \"log_url\": \"https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"}" \
    >> /dev/null


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
    -d "{\"environment\": \"PR $pull_request_id\", \"environment_url\": \"$4/$pull_request_id\", \"state\": \"success\", \"log_url\": \"https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\"}" \
    >> /dev/null

  curl \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: token $2" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/"$3"/pages/builds >> /dev/null

  echo "Successfully deployed preview for PR #$pull_request_id!"

  cd ..
  rm -r preview-deployment
  cd "$GITHUB_WORKSPACE" || exit 1
fi

result3=$(curl -H "Authorization: token $1" -H "Accept: application/vnd.github.v3.full+json" \
 https://api.github.com/repos/"$GITHUB_REPOSITORY"/pulls/"$pull_request_id"/files)
files=$(echo "$result3" | jq -r '.[] | select(.filename|test(".*\\.html")) | "\(.filename)-\(.status)"')

echo "A preview for this pull request is available at $4/$pull_request_id."
echo "Here are some links to the pages that were modified:"

for file in $files
do
  file_name=$(echo "$file" | awk -F - '{print $1}')
  type=$(echo "$file" | awk -F - '{print $2}')
  echo "- $type: $4/$pull_request_id/$file_name"
done
