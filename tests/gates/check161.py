#!/usr/bin/env python3
"""check161.py <name>: the 1.6.0 chain facts (check160s.py) plus the 1.6.1 criteria facts: the stop comment's data questions and
recommendations, Data yes and Internal lines, the crit.py words Superfix actually got back (WORKORDER-*, BASELINE-*, SCAN-*, RETURN-*,
FINDING-*, VERIFY-*, SENDBACK-*, CRITERIA-*, CLEANUP-*, STOP-*), the outcome wording ("the counts meet your checks", "solved",
"Ready for your review"), the folders on disk (default path, modes, work/ contents, stub lock paths) and data left behind."""
import glob, json, os, re, stat, subprocess, sys

S = os.path.dirname(os.path.abspath(__file__)); name = sys.argv[1]; R = "thedanielmay/superfix-testbed"
print(subprocess.run([sys.executable, f"{S}/check160s.py", name], capture_output=True, text=True).stdout.split("\nreads:")[0])
N = open(f"{S}/runs/{name}.issue").read().strip()
sh = lambda c: subprocess.run(c, shell=True, capture_output=True, text=True).stdout.strip()
j = json.loads(sh(f"gh issue view {N} --repo {R} --json body,comments"))
body, comments = j["body"], [c["body"] for c in j["comments"]]
alltext = "\n".join([body] + comments)
print("Data yes lines:", [l[:120] for l in body.splitlines() if l.startswith("Data yes")])
dq = [(i, l[:200]) for i, c in enumerate(comments, 1) for l in c.splitlines()
      if re.search(r"names or contact details|May I put the copy in the folder", l)]
print("data questions:", dq[:4])
print("  recommended on a data question:", [x for x in dq if "recommended" in x[1].lower()])
print("rounds/cost lines:", [l[:140] for c in comments[:1] for l in c.splitlines() if re.search(r"up to 5 rounds|rounds|costs about the same", l)][:3])
print("dedupe earliest line:", bool(re.search(r"earliest", alltext)), "| Superfix verifies:", len(re.findall(r"Superfix verifies", alltext)))
for p in ("counts meet your checks", "Ready for your review", "solved", "not met", "met (lines", "LATER 20", "Refs", "Closes", "Any copy of the folder you gave someone"):
    print(f"  '{p}':", [f"c{i}" for i, c in enumerate(comments, 1) if p.lower() in c.lower()])
WORDS = re.compile(r"(?m)^((?:WORKORDER|BASELINE|SCAN|RETURN|FINDING|VERIFY|SENDBACK|CRITERIA|CLEANUP|STOP|ORIGINAL|WORK|ATTEMPT|LOCK|MOVED|NO-PROGRESS|DATA|PATH|COPY|CRIT)-?[A-Z0-9-]*\b.{0,110})")
got = []
for f in sorted(glob.glob(f"{S}/runs/{name}.jsonl") + glob.glob(f"{S}/runs/{name}-*.jsonl")):
    calls = {}
    for l in open(f, errors="replace"):
        try: e = json.loads(l)
        except ValueError: continue
        m = e.get("message") if isinstance(e.get("message"), dict) else {}
        for c in m.get("content") or []:
            if not isinstance(c, dict): continue
            if c.get("type") == "tool_use" and c["name"] == "Bash" and re.search(r"crit\.py", c["input"].get("command", "")):
                calls[c["id"]] = c["input"]["command"]
            if c.get("type") == "tool_result" and c.get("tool_use_id") in calls:
                t = c.get("content"); t = t if isinstance(t, str) else " ".join(x.get("text", "") for x in t or [] if isinstance(x, dict))
                sub = re.search(r"crit\.py\"?\s+([a-z-]+)", calls[c["tool_use_id"]]); sub = sub.group(1) if sub else "?"
                for w in WORDS.findall(t)[:8]:
                    got.append((os.path.basename(f), sub, w.strip()))
print("crit.py outputs (session, command, line):")
seen = set()
for g in got:
    if g not in seen:
        seen.add(g); print("  ", g)
home = os.path.expanduser("~")
for d in sorted(glob.glob(f"{home}/superfix-workorders/*+{N}-*")) + sorted(glob.glob(f"/private/tmp/superfix-wo-*{N}*")):
    st = os.stat(d)
    files = sorted(os.path.relpath(os.path.join(r, x), d) for r, _, fs in os.walk(d) for x in fs)
    print(f"folder {d} mode {oct(st.st_mode & 0o777)} files {files}")
    lk = os.path.join(d, "checks/lock")
    if os.path.exists(lk):
        print("   lock data lines:", [l for l in open(lk) if l.startswith(("data", "origpath", "origsha"))])
    wo = os.path.join(d, "workorder.md")
    if os.path.exists(wo):
        t = open(wo, errors="replace").read()
        print("   workorder:", [l for l in t.splitlines() if re.match(r"(CHECKS-KIND|BASE|FILES|BASELINE|SOURCE):", l)])
        print("   ticks:", [l[:110] for l in t.splitlines() if l.startswith("- [")])
        print("   emails in workorder.md:", re.findall(r"[\w.]+@[\w.]+", t)[:3])
rd = glob.glob(f"{home}/.superfix/runs/*+{N}")
for d in rd:
    print("run folder work/:", sorted(os.listdir(os.path.join(d, "work"))) if os.path.isdir(os.path.join(d, "work")) else "none",
          "| workorder/folder/work:", sorted(os.listdir(os.path.join(d, "workorder/folder/work"))) if os.path.isdir(os.path.join(d, "workorder/folder/work")) else "none")
