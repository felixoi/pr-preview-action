#!/bin/sh

pr=$(echo "$GITHUB_REF" | awk -F / '{print $3}')

# use PAT if no github token is set
if [ -z "$1" ]
then
      "$1"="$2"
fi

cd "$GITHUB_WORKSPACE/" || exit 1
cd ..

git clone "https://$2@github.com/$3.git" preview-deployment

cd "preview-deployment" || exit 1
git config user.name "felixoi"
git config user.email "felixoi@users.noreply.github.com"

mkdir -p "$pr"
if [ -d "$pr" ]; then
  echo "Updating preview for pull request #$pr..."
  rm -r ./"$pr"
  rsync -avz "$GITHUB_WORKSPACE/" "$pr" --exclude='.git' --exclude '.github'
else
  echo "Creating preview for pull request #$pr..."
  rsync -avz "$GITHUB_WORKSPACE/" "$pr" --exclude='.git' --exclude '.github'
fi

if [ -z "$(git status --porcelain)" ]
then
  echo "Preview for PR #$pr is already up-to-date!"
else
  python3 /scripts/deployment_create.py

  git add -A
  git commit -q -m "Deployed preview for PR #$pr"
  git push -q origin gh-pages

  python3 /scripts/deployment_success.py

  curl \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: token $2" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/"$3"/pages/builds >> /dev/null

  echo "Successfully deployed preview for PR #$pr!"

  cd ..
  rm -r preview-deployment
  cd "$GITHUB_WORKSPACE" || exit 1
fi

result3=$(curl -H "Authorization: token $1" -H "Accept: application/vnd.github.v3.full+json" \
 https://api.github.com/repos/"$GITHUB_REPOSITORY"/pulls/"$pr"/files)
files=$(echo "$result3" | jq -r '.[] | select(.filename|test(".*\\.html")) | "\(.filename)-\(.status)"')

body="A preview for this pull request is available at $4/$pr.\n\nHere are some links to the pages that were modified:"

for file in $files
do
  file_name=$(echo "$file" | awk -F - '{print $1}')
  type=$(echo "$file" | awk -F - '{print $2}')
  body="$body\n- $type: $4/$pr/$file_name"
done

login="github-actions"
token=$1
if echo "$5" | grep -iqF true; then
    result4=$(curl -H "Authorization: token $1" -H "Accept: application/vnd.github.v3.full+json" \
      https://api.github.com/user)

    login=$(echo "$result4" | jq -r '.login')
    token=$2
fi

result5=$(curl -H "Authorization: token $token" -H "Accept: application/vnd.github.v3.full+json" \
 https://api.github.com/repos/"$GITHUB_REPOSITORY"/issues/"$pr"/comments)
comment=$(echo "$result5" | jq -r "first(.[] | select(.user.login|test(\"$login\")) | .id)")

if [ -z "$comment" ]
then
  curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: token $token" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/"$GITHUB_REPOSITORY"/issues/"$pr"/comments \
  -d "{\"body\":\"$body\"}" \
  >> /dev/null
else
  curl -X PATCH \
  -H "Content-Type: application/json" \
  -H "Authorization: token $token" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/"$GITHUB_REPOSITORY"/issues/comments/"$comment" \
  -d "{\"body\":\"$body\"}"
fi

