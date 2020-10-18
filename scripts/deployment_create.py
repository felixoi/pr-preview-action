#!/usr/bin/env python

import json
import os

import requests

github_base = os.environ['GITHUB_SERVER_URL']
github_api = os.environ['GITHUB_API_URL']
run_id = os.environ['GITHUB_RUN_ID']
token = os.environ['INPUT_PA_TOKEN'] if os.getenv('INPUT_FORCE_PAT', 'false').lower() == 'true' \
    else os.environ['INPUT_GITHUB_TOKEN']
headers = {
    'Authorization': 'token ' + token,
    'Accept': 'application/vnd.github.v3.full+json'
}
pr = os.environ['GITHUB_REF'].split('/')[2]
repo = os.environ['GITHUB_REPOSITORY']
pages_base = os.environ['INPUT_GITHUB_PAGES_BASE']

r = requests.get(f'{github_api}/repos/{repo}/pulls/{pr}', headers)
r.raise_for_status()
branch = r.json()['head']['ref']

r = requests.post(f'{github_api}/repos/{repo}/deployments',
                  data=json.dumps({
                      "ref": branch,
                      "environment": f"PR-{pr}",
                      "required_contexts": [],
                      "auto_merge": False
                  }),
                  headers=headers)
r.raise_for_status()
deployment_id = r.json()['id']

headers_custom = headers.copy()
headers_custom['Authorization'] = 'token ' + os.environ['INPUT_GITHUB_TOKEN']
headers_custom['Accept'] = "application/vnd.github.v3+json,application/vnd.github.ant-man-preview+json," \
                           "application/vnd.github.flash-preview+json"
print(headers_custom)
r = requests.post(f'{github_api}/repos/{repo}/deployments/{deployment_id}/statuses',
                  json.dumps({
                      "environment": f"PR-{pr}",
                      "environment_url": f"{pages_base}/{pr}",
                      "state": "in_progress",
                      "log_url": f"{github_base}/{repo}/actions/runs/{run_id}"
                  }), headers_custom)
r.raise_for_status()

pr = os.environ['DEPLOYMENT_ID'] = f"{deployment_id}"

print("HELLLOOOO")
