#!/usr/bin/env python

import json
import os

force_pat = os.environ['5']

print("hello from python")
for k, v in os.environ.items():
    print(f'{k}={v}')
