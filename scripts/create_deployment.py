#!/usr/bin/env python

import json
import os

force_pat = os.getenv('INPUT_FORCE_PAT', 'false').lower() == 'true'

if force_pat:
    print("FORCEEE")