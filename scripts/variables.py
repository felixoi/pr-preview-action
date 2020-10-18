#!/usr/bin/env python

import os

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
