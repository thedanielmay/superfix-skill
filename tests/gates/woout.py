#!/usr/bin/env python3
"""woout.py <jsonl> [pattern]: each Bash call matching pattern (default crit.py wo-, git push, gh pr create) and the tail of its output."""
import json, re, sys
pat = re.compile(sys.argv[2] if len(sys.argv) > 2 else r"crit\.py\"? wo-|git push|gh pr create|wo-sendback")
calls, res = {}, {}
for l in open(sys.argv[1], errors="replace"):
    try: e = json.loads(l)
    except ValueError: continue
    m = e.get("message") if isinstance(e.get("message"), dict) else {}
    for c in m.get("content") or []:
        if not isinstance(c, dict): continue
        if c.get("type") == "tool_use" and c["name"] == "Bash" and pat.search(c["input"].get("command", "")):
            calls[c["id"]] = c["input"]["command"]
        if c.get("type") == "tool_result" and c.get("tool_use_id") in calls:
            t = c.get("content"); t = t if isinstance(t, str) else " ".join(x.get("text", "") for x in t or [] if isinstance(x, dict))
            ws = re.findall(r"(?m)^(?:RETURN-|VERIFY-|SOLVED-|SUITE-|TESTNAMES-|SENDBACK-|NO-PROGRESS|BASELINE-|WORKORDER-|CHECK [CHK]\d+ FAIL|To https|https://github.com/\S+/pull/)\S*.{0,90}", t)
            print("CMD", re.sub(r"\s+", " ", calls[c["tool_use_id"]])[-110:]); [print("   ", w) for w in ws[:14]]
