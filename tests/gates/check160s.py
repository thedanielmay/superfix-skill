#!/usr/bin/env python3
"""check160s.py <name>: facts about one Superfix chain (runs/<name>*.jsonl, issue in runs/<name>.issue).
Reads the issue, the PRs, the transcripts (words crit.py printed, files read, questions asked, cost), the run clone and the work order folders."""
import glob, json, os, re, subprocess, sys

S = os.path.dirname(os.path.abspath(__file__)); name = sys.argv[1]; R = "thedanielmay/superfix-testbed"
N = open(f"{S}/runs/{name}.issue").read().strip()
sh = lambda c: subprocess.run(c, shell=True, capture_output=True, text=True).stdout.strip()
j = json.loads(sh(f"gh issue view {N} --repo {R} --json body,comments,labels,state"))
body, comments, labels = j["body"], [c["body"] for c in j["comments"]], [l["name"] for l in j["labels"]]
print(f"## {name} issue {N}: state {j['state']} labels {labels} comments {len(comments)}")
st = [l for l in body.split("\n") if l.startswith("**Status:**")]
print("Status:", st[:1])
def lines(p):
    return [("body" if i == 0 else f"c{i}", l[:160]) for i, t in enumerate([body] + comments) for l in t.split("\n") if l.startswith(p)]
for p in ("Work order:", "Executor:", "Criteria:", "Labels:", "Pictures:", "Diagram:", "Gap note:", "Internal:"):
    print(p, lines(p))
print("comment starts:", [c[:90].replace("\n", " ") for c in comments])
prs = json.loads(sh(f'gh pr list --repo {R} --state all --search "{N} in:body" --json number,state,headRefName,headRefOid') or "[]")
for p in prs[:3]:
    print("PR", p["number"], p["state"], p["headRefName"], p["headRefOid"][:12], "files:", sh(f"gh pr diff {p['number']} --repo {R} --name-only").split("\n")[:10])
print("remote branches:", sh(f"git ls-remote --heads https://github.com/{R}.git | awk '{{print $2}}' | grep -v main | tr '\\n' ' '"))
WORDS = re.compile(r"\b(BASELINE-OK|BASELINE-MISMATCH|WORKORDER-OK|WORKORDER-[A-Z-]+|RETURN-[A-Z-]+|VERIFY-PASS|VERIFY-FAIL|VERIFY-PROBLEM|SOLVED-[A-Z0-9-]+|SUITE-[A-Z-]+|TESTNAMES-OK|SENDBACK-[A-Z]+|NO-PROGRESS|SANDBOX-MISSING|SANDBOX-EXIT \S+|CLEAN|NO-LIST|PATTERN-HITS|LINES-OK|LINES-MISSING|CRITERIA-[A-Z-]+)\b")
tot = 0; words = []; reads = set(); asks = []; cmds = []; S13 = []
BAD = re.compile(r"\b(gws|osascript|tw|curl|wget|ssh|scp|rsync|sendmail)\b|gh (gist|release create|repo create)|Library/CloudStorage")
for f in sorted(glob.glob(f"{S}/runs/{name}.jsonl") + glob.glob(f"{S}/runs/{name}-*.jsonl")):
    sess = os.path.basename(f); fc = 0
    for l in open(f, errors="replace"):
        try:
            e = json.loads(l)
        except ValueError:
            continue
        if e.get("type") == "result":
            fc = max(fc, e.get("total_cost_usd") or 0)
            words.append((sess, "RESULT-TEXT", (e.get("result") or "")[-300:].replace("\n", " ")))
        m = e.get("message") if isinstance(e.get("message"), dict) else {}
        for c in m.get("content") or []:
            if not isinstance(c, dict):
                continue
            if c.get("type") == "tool_use":
                i = c.get("input") or {}
                if c["name"] == "Read":
                    reads.add(os.path.basename(i.get("file_path", "")))
                if c["name"] == "Bash":
                    cmd = i.get("command", "")
                    if re.search(r"crit\.py\"? (wo-|sandbox)|git push|gh pr create|superfix-workorders", cmd):
                        cmds.append((sess, cmd[:150].replace("\n", " ")))
                    if BAD.search(cmd):
                        S13.append(cmd[:100])
            if c.get("type") == "tool_result":
                t = c.get("content")
                t = t if isinstance(t, str) else " ".join(x.get("text", "") for x in t or [] if isinstance(x, dict))
                for w in dict.fromkeys(WORDS.findall(t)):
                    words.append((sess, w))
    tot += fc
print(f"cost USD {round(tot, 2)}")
print("reads:", sorted(r for r in reads if r.endswith(".md")))
print("crit and push commands:"); [print("  ", c) for c in cmds[:40]]
print("words:"); seen = []
for w in words:
    if w not in seen:
        seen.append(w)
for w in seen:
    print("  ", w)
print("S13 hits:", S13[:5])
d = f"{S}/runs/{name}"
print("clone branches:", sh(f"git -C {d} branch --format='%(refname:short)' | tr '\\n' ' '"), "| porcelain:", repr(sh(f"git -C {d} status --porcelain")[:200]))
print("workorder folders:", sh(f"ls -d $HOME/superfix-workorders/*+{N}-* 2>/dev/null"), "|", sh(f"ls $HOME/superfix-workorders/*+{N}-*/ 2>/dev/null | tr '\\n' ' '"))
print("run folder workorder/:", sh(f"ls $HOME/.superfix/runs/*+{N}/workorder/ 2>/dev/null | tr '\\n' ' '"))
