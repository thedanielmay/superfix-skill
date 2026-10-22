#!/bin/bash
python3 -c "
import json,sys
for l in open(sys.argv[1]):
    try: e=json.loads(l)
    except: continue
    if e.get('session_id'): print(e['session_id']); break" "$1"
