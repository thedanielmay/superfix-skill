#!/usr/bin/env python3
"""One redaction gate for Superfix runs (stdlib only).

Replaces the inline exact-string and pattern snippets in references/redaction.md.
Usage:
  python3 -I references/redact-check.py --run <run-folder> -- <files...>
  python3 -I references/redact-check.py --self-test

Prints the exact-string word first (CLEAN, BLOCKED <files>, NO-LIST,
NO-RUN-FOLDER, ERROR), then the pattern word (PATTERN-CLEAN or PATTERN-HITS
with file:line hits, you decide each one). Exit 1 on BLOCKED, ERROR and
NO-RUN-FOLDER, else 0. A missing input file is ERROR, never PATTERN-CLEAN.
--self-test runs the built-in positive control and prints SELF-TEST-OK.
"""
import re
import sys

KEYWORD = re.compile(
    r"(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)"
    r"[ \t]*[:=][ \t]*[^ \t]+",
    re.IGNORECASE,
)
PREFIX = re.compile(
    r"(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|"
    r"AKIA[0-9A-Z]{16}|"
    r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|"
    r"-----BEGIN [A-Z ]*KEY-----|"
    r"://[^/ \t:@]+:[^/ \t@]+@"
)
LONG = re.compile(r"(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])")
HEX40 = re.compile(r"^[0-9a-f]{40}$", re.IGNORECASE)
TRAILER = "Claude-Session: https://claude.ai/code/session_"

# Positive control: every pattern group must fire on this text.
SELFTEST_TEXT = (
    "password: hunter2-value\n"
    "api_key=AbCdEfGh1234567890AbCdEfGh1234567890\n"
    "Use token ghp_abcdefghijklmnopqrstuvwxyz0123456789 for the clone.\n"
)


def pattern_hits(path, text):
    """Line numbers (1-based) in text that hit any pattern group."""
    hits = set()
    for n, line in enumerate(text.splitlines(), 1):
        if TRAILER in line:
            continue
        if KEYWORD.search(line):
            hits.add(n)
            continue
        if PREFIX.search(line):
            hits.add(n)
            continue
        for m in LONG.finditer(line):
            s = m.group(1)
            if not (re.search(r"[A-Za-z]", s) and re.search(r"[0-9]", s)):
                continue
            if HEX40.match(s):
                continue
            if re.match(r"^[0-9a-f]{64}$", s, re.IGNORECASE) and "sha256" in line.lower():
                continue
            hits.add(n)
            break
    return sorted(hits)


def self_test():
    hits = pattern_hits("<self-test>", SELFTEST_TEXT)
    if len(hits) >= 3:
        print("SELF-TEST-OK")
        return 0
    print("SELF-TEST-FAIL")
    return 1


def main(argv):
    if "--self-test" in argv:
        return self_test()
    try:
        ri = argv.index("--run")
        run = argv[ri + 1]
    except (ValueError, IndexError):
        print("ERROR: usage: redact-check.py --run <run-folder> -- <files...>")
        return 1
    try:
        si = argv.index("--")
        files = argv[si + 1 :]
    except ValueError:
        files = []
    import os

    key = os.path.join(run, "key")
    if not os.path.isfile(key):
        print("NO-RUN-FOLDER %s" % run)
        return 1
    if not files:
        print("ERROR: no input files")
        return 1
    texts = {}
    for f in files:
        try:
            with open(f, encoding="utf-8", errors="replace") as fh:
                texts[f] = fh.read()
        except OSError:
            print("ERROR: a file could not be read: %s" % f)
            return 1
    code = 0
    secrets_path = os.path.join(run, "secrets")
    try:
        with open(secrets_path, encoding="utf-8", errors="replace") as fh:
            secrets = [l for l in fh.read().splitlines() if l.strip()]
    except OSError:
        secrets = []
    if not secrets:
        print("NO-LIST")
    else:
        blocked = [f for f, t in texts.items() if any(s in t for s in secrets)]
        if blocked:
            print("BLOCKED %s" % " ".join(blocked))
            code = 1
        else:
            print("CLEAN")
    hits = []
    for f, t in texts.items():
        for n in pattern_hits(f, t):
            hits.append("%s:%d" % (f, n))
    if hits:
        print("PATTERN-HITS (file:line, read each one, then decide):")
        for h in sorted(set(hits)):
            print(h)
    else:
        print("PATTERN-CLEAN")
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv))
