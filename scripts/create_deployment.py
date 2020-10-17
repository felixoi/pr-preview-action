#!/usr/bin/env python

import json
import os

print("hello from python")
for k, v in os.environ.items():
    print(f'{k}={v}')
