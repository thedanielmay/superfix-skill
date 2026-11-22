#!/bin/bash
# Fails when a tracked file holds personal data in a shape this check can know (superfix-skill#136):
#   a home path with a literal user name, a path flattened into a folder name,
#   an email-shaped Google Drive path, or a tracked compiled Python file.
# It prints file:line only, never the matched text, because CI logs of a public repo are public.
# Names of clients or private repos cannot be listed here without leaking them, so they are not checked.
# No model runs, no network. Needs: git, grep.
# Usage: bash tests/leak-check.sh
# ROOT=<another checkout> runs the check against that checkout (used to show it fails before its fix).
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
T="$(mktemp -d "${TMPDIR:-/tmp}/leak-check.XXXXXX")"
trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok() { pass=$((pass+1)); echo "ok   $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }

# scan <root>: print file:line for each hit; print no matched text.
scan() {
  local r="$1" p
  for p in '/Users/[A-Za-z0-9._-]+/' '-Users-[A-Za-z0-9]+-' 'GoogleDrive-[A-Za-z0-9.-]+-(com|org|net|au)'; do
    git -C "$r" grep -a -n -E -e "$p" -- . | cut -d: -f1,2
  done
  git -C "$r" ls-files | grep -E '\.pyc$|(^|/)__pycache__/' | sed 's/$/:1/'
}

if [ -z "$(git -C "$ROOT" ls-files | head -1)" ]; then echo "FAIL no tracked files (wrong ROOT?)"; exit 1; fi
hits="$(scan "$ROOT")"
if [ -z "$hits" ]; then ok "no personal path, Drive email path or compiled file in a tracked file"
else bad "personal data shapes found at (file:line, text not shown):"; printf '%s\n' "$hits" | sort -u; fi

# positive control: each shape, built from pieces so this file does not hold one, must be caught
M="$T/m"; mkdir -p "$M/__pycache__"; git -C "$M" init -q
a="/Us"; b="ers"; printf 'x %s%s/someone/y\n' "$a" "$b" > "$M/a.txt"
printf 'x -%s-someone-y\n' "Us$b" > "$M/b.txt"
printf 'x Google%s-some.one-com\n' "Drive" > "$M/c.txt"
printf 'x' > "$M/__pycache__/d.pyc"
printf 'safe /Users/<you>/ and /Users/ and /Users/[^/]+/\n' > "$M/e.txt"
git -C "$M" add -A
mh="$(scan "$M")"
for f in a.txt b.txt c.txt __pycache__/d.pyc; do
  if printf '%s\n' "$mh" | grep -q "^$f:"; then ok "control: $f caught"; else bad "control: $f not caught"; fi
done
if printf '%s\n' "$mh" | grep -q '^e.txt:'; then bad "control: placeholders flagged"; else ok "control: placeholders pass"; fi
if printf '%s\n' "$mh" | grep -q 'someone'; then bad "control: output shows matched text"; else ok "control: output shows no matched text"; fi

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
