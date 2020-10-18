#!/usr/bin/env python

import json
import os

import requests

from variables import github_api, repo, pr, pages_base, github_base, run_id, headers

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
r = requests.post(f'{github_api}/repos/{repo}/deployments/{deployment_id}/statuses',
                  json.dumps({
                      "environment": f"PR-{pr}",
                      "environment_url": f"{pages_base}/{pr}",
                      "state": "in_progress",
                      "log_url": f"{github_base}/{repo}/actions/runs/{run_id}"
                  }), headers=headers_custom)
r.raise_for_status()

os.environ['DEPLOYMENT_ID'] = f"{deployment_id}"
