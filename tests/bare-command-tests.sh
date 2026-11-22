#!/bin/bash
# Fails when a backticked span starts with a crit.py subcommand (wo-<name>) plus arguments,
# without python3 and crit.py in the same span (superfix-skill#134).
# No model runs, no network. Needs: python3, git.
# Usage: bash tests/bare-command-tests.sh
# Also fails when a command runs a references/ script by a path relative to the current folder, in a span or a code block (superfix-skill#138).
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
if not files:
    print(f"SCAN-NO-FILES (wrong ROOT?)"); sys.exit(2)
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

# a command that runs a references/ script by a relative path, in a backticked span or inside a fenced code block (superfix-skill#138)
cat > "$T/rel.py" <<'PY'
import re, sys, pathlib
root = pathlib.Path(sys.argv[1])
files = [p for pat in ("SKILL.md", "README.md", "skills/*/SKILL.md", "skills/superfix/references/*.md") for p in sorted(root.glob(pat))]
if not files:
    print("SCAN-NO-FILES (wrong ROOT?)"); sys.exit(2)
# the interpreter may sit anywhere in the line (after cd ... &&, a pipe or a $ prompt); ./references/ counts too
cmd_re = re.compile(r'(?:^|[\s;&|$(])(python3?|bash|sh)( -I)? "?(\./)?references/')
n = 0; full = 0
for f in files:
    fence = ""   # the opening fence string; a fence closes only on the same character, at least as long
    for i, line in enumerate(f.read_text().splitlines(), 1):
        full += line.count("<skill dir>/references/")
        m = re.match(r"\s*(`{3,}|~{3,})", line)
        if m:
            tok = m.group(1)
            if not fence:
                fence = tok
                continue
            if tok[0] == fence[0] and len(tok) >= len(fence) and not line.strip()[len(tok):].strip():
                fence = ""
                continue
        hit = cmd_re.search(line) if fence else any(cmd_re.search(s) for s in re.findall(r"`([^`]+)`", line))
        if hit:
            n += 1
            print(f"RELATIVE {f.relative_to(root)}:{i}: {line.strip()[:60]}")
print(f"CONTROL {full}")
print(f"TOTAL {n}")
PY
out="$(python3 -I "$T/rel.py" "$ROOT")"
if [ "$(printf '%s\n' "$out" | tail -1)" = "TOTAL 0" ]; then ok "no references/ script run by a relative path"
else bad "relative references/ commands found (name them as <skill dir>/references/..., as workorder.md does):"; printf '%s\n' "$out" | grep '^RELATIVE'; fi
c=$(printf '%s\n' "$out" | sed -n 's/^CONTROL //p')
if [ "${c:-0}" -ge 5 ]; then ok "control: $c lines name <skill dir>/references/"; else bad "relative scan broken: only ${c:-0} lines name <skill dir>/references/ (want 5 or more)"; fi

# mutant: put a relative project.py line back into a code block of a copy of project.md; the scan must go red
mkdir -p "$T/m2/skills/superfix/references"
cp "$ROOT/skills/superfix/references/project.md" "$T/m2/skills/superfix/references/"
M2="$T/m2/skills/superfix/references/project.md"
printf '\n````\npython3 references/project.py <repo>\n````\n' >> "$M2"
if python3 -I "$T/rel.py" "$T/m2" | grep -q '^RELATIVE'; then ok "mutant: a relative project.py line in a code block is caught"
else bad "relative-path mutant not caught"; fi

# mutant: an inline relative span (the SKILL.md form) and a nested three-backtick line inside a four-backtick block
mkdir -p "$T/m3/skills/superfix/references"
cp "$ROOT/skills/superfix/references/project.md" "$T/m3/skills/superfix/references/"
M3="$T/m3/skills/superfix/references/project.md"
printf '\nRun `cd x && python3 references/project.py .` first.\n\n````\n```\npython3 -I references/crit.py lock\n````\n' >> "$M3"
n3=$(python3 -I "$T/rel.py" "$T/m3" | grep -c '^RELATIVE')
if [ "$n3" -ge 2 ]; then ok "mutant: an inline relative span and a command after a nested fence are caught ($n3)"
else bad "inline or nested-fence mutant not caught (found $n3, want 2)"; fi

echo "pass $pass fail $fail"
[ "$fail" -eq 0 ]
