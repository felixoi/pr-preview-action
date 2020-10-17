#!/usr/bin/env python

import json
import os

import requests

github_api = os.environ['GITHUB_API_URL']
token = os.environ['INPUT_PA_TOKEN'] if os.getenv('INPUT_FORCE_PAT', 'false').lower() == 'true' \
    else os.environ['GITHUB_TOKEN']
headers = {
    'Authorization': 'token ' + token,
    'Accept': 'application/vnd.github.v3.full+json'
}
pr = os.environ['GITHUB_REF'].split('/')[2]
repo = os.environ['GITHUB_REPOSITORY']

r = requests.get(f'{github_api}/repos/{repo}/pulls/{pr}', headers)
r.raise_for_status()
print(r.json()['head']['ref'])
