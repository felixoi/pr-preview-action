#!/usr/bin/env python

import json
import os

import requests

from variables import github_api, repo, pr, pages_base, github_base, run_id, headers

deployment_id = os.environ['DEPLOYMENT_ID']

r = requests.post(f'{github_api}/repos/{repo}/deployments/{deployment_id}/statuses',
                  data=json.dumps({
                      "environment": f"PR-{pr}",
                      "environment_url": f"{pages_base}/{pr}",
                      "state": "success",
                      "log_url": f"{github_base}/{repo}/actions/runs/{run_id}"
                  }),
                  headers=headers)
r.raise_for_status()
