#!python
import json
import os
import sys

import requests

from variables import repo, pr

comment_template = """
A preview for this pull request is available at %s/%s/.

Here are some links to the pages that were modified:

%s

_Since the preview frequently changes, please link to [this comment](%s), not to the direct url to the preview._
"""


def make_comment(commit, comment, changes):
    return {
        'body': comment_template % (rawgit,
                                    commit,
                                    '\n'.join('- %s: %s/%s/%s.html' % (change['status'],
                                                                       rawgit,
                                                                       commit,
                                                                       change['filename']) for change in changes),
                                    comment)
    }


def map_change(change):
    filename = change['filename']
    return {'filename': filename[filename.find('/')+1:filename.rfind('.')], 'status': change['status']}


def filter_change(change):
    filename = change['filename']
    status = change['status']
    return filename.startswith('source/') and filename.endswith('.rst') and status in ['added', 'renamed', 'modified']

r = requests.get('%s/pulls/%s/files' % (repo, pr), auth=('x-oauth-basic', token))
r.raise_for_status()
files = r.json()

changes = [map_change(change) for change in files if filter_change(change)]
changes = [change for change in changes if change['status'] == 'added'] \
          + [change for change in changes if change['status'] == 'renamed'] \
          + [change for change in changes if change['status'] == 'modified']

comments = requests.get('%s/issues/%s/comments' % (repo, pr), auth=('x-oauth-basic', token)).json()
spongy_comments = [comment for comment in comments if comment['user']['login'] == 'Spongy']

if spongy_comments:
    # Use existing comment
    comment = spongy_comments[0]
else:
    # Post new comment
    payload = {'body': 'Setting up PR reference, please wait...'}
    r = requests.post(
        '%s/issues/%s/comments' % (repo, pr),
        auth=('x-oauth-basic', token),
        data=json.dumps(payload))
    r.raise_for_status()
    comment = r.json()

comment_id = comment['id']
comment_url = comment['html_url']
r = requests.patch(
    '%s/issues/comments/%s' % (repo, comment_id),
    auth=('x-oauth-basic', token),
    data=json.dumps(make_comment(commit, comment_url, changes)))
r.raise_for_status()