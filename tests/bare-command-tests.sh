#!/bin/bash
# Fails when a backticked span starts with a crit.py subcommand (wo-<name>) plus arguments,
# without python3 and crit.py in the same span (superfix-skill#134).
# No model runs, no network. Needs: python3, git.
# Usage: bash tests/bare-command-tests.sh
# ROOT=<another checkout> runs these tests against that checkout's files (used to show a test fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
T="$(mktemp -d "${TMPDIR:-/tmp}/bare-command-tests.XXXXXX")"
trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok() { pass=$((pass+1)); echo "ok   $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }

cat > "$T/scan.py" <<'PY'
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
files = [p for pat in ("SKILL.md", "README.md", "skills/*/SKILL.md", "skills/superfix/references/*.md") for p in sorted(root.glob(pat))]
bare = re.compile(r"^wo-[a-z]+(-[a-z]+)*\s+\S")
n = 0
for f in files:
    for i, line in enumerate(f.read_text().splitlines(), 1):
        for span in re.findall(r"`([^`]+)`", line):
            if bare.match(span):
                n += 1
                print(f"BARE {f.relative_to(root)}:{i}: `{span[:60]}`")
print(f"TOTAL {n}")
PY
out="$(python3 -I "$T/scan.py" "$ROOT")"
if [ "$(printf '%s\n' "$out" | tail -1)" = "TOTAL 0" ]; then ok "no short gate command in a backticked span"
else bad "short forms found (name crit.py, as workorder.md section 6 shows):"; printf '%s\n' "$out" | grep '^BARE'; fi

# positive control: the full form must be found in workorder.md
n=$(grep -cE 'crit\.py"? wo-[a-z-]+ --' "$ROOT/skills/superfix/references/workorder.md")
if [ "$n" -ge 7 ]; then ok "control: $n full forms in workorder.md"; else bad "scan broken: only $n full forms in workorder.md (want 7 or more)"; fi

# SKILL.md must send the model to references/crit.py for the comment gate
for g in wo-scan-comment wo-post; do
  if grep -qF "references/crit.py\" $g" "$ROOT/skills/superfix/SKILL.md"; then ok "SKILL.md names references/crit.py for $g"
  else bad "SKILL.md does not name references/crit.py for $g"; fi
done

# mutant: put one short form back on a line that also holds a full form; the scan must go red
mkdir -p "$T/m/skills/superfix/references"
cp "$ROOT/skills/superfix/references/workorder.md" "$T/m/skills/superfix/references/"
M="$T/m/skills/superfix/references/workorder.md"
python3 -I - "$M" <<'PYM'
import sys
p = sys.argv[1]
L = open(p).read().split("\n")
for i, l in enumerate(L):
    if 'python3 -I "D/crit.py" wo-lock' in l:
        L[i] = l + ' Short form back: `wo-lock --run "D"`.'
        break
open(p, "w").write("\n".join(L))
PYM
if ! cmp -s "$M" "$ROOT/skills/superfix/references/workorder.md" \
   && python3 -I "$T/scan.py" "$T/m" | grep -q '^BARE'; then ok "mutant: one short form on a line with a full form is caught"
else bad "mutant not caught"; fi

echo "pass $pass fail $fail"
[ "$fail" -eq 0 ]
