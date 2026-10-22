#!/usr/bin/env python3
"""Read <repo>/.superfix/project.md and print the settings Superfix applies.

Usage: python3 references/project.py [REPO]      (REPO defaults to the current folder)

Standard library only. It never runs, expands or fetches anything: it reads one
file and judges it. The format and the keys are in references/project.md.

Output, one line per item, the status line first:
  PROJECT-OK                     every setting applied
  PROJECT-UNKNOWN-KEY <key>      a key that is not known: ignored, still applied the rest
  PROJECT-REFUSED <key>          a key, or a rules line, that would relax a safeguard: nothing applied
  PROJECT-CHECK-REFUSED <key>    a checks command outside the allowlist: nothing applied
  PROJECT-BAD-VALUE <key>        a value that is not a ref, or names a credential path
                                 or an outbound destination: nothing applied
  SETTING <key>=<value>          one per applied value, in file order
  IGNORED <key>                  one per unknown key
  SETTINGS-NONE                  the file is absent or holds no settings
Exit 0 for OK and UNKNOWN-KEY (the run continues), 1 for the three stops.
"""
import pathlib, re, sys

FILE = ".superfix/project.md"
SINGLE = ("base-branch", "pr-base")
MULTI = ("checks", "rules", "do-not-edit")
ALLOWED = SINGLE + MULTI
# A key holding one of these words is trying to loosen a safeguard, so the run stops.
REFUSED = ("gate", "secre", "redact", "merge", "push", "budget", "approv", "bypass",
           "allow", "skip", "permission", "credential", "token", "password", "dest",
           "upload", "clone", "force", "unsafe", "trust", "sudo", "confirm", "create",
           "relax")
# No value may name an outbound destination or a credential path.
OUTBOUND = ("://", "git@", "scp:", "rsync:", "s3:")
CREDENTIAL = ("~/.ssh", "/.ssh/", ".env", "id_rsa", "id_ed25519", ".netrc", ".aws/",
              ".gnupg", ".kube/config", "keychain", "credentials.json", ".docker/config")
# checks: the interpreter, the repository script it runs, then plain arguments.
INTERPRETERS = ("python3", "python", "bash", "sh", "node")
FLAGS = ("-I", "-u", "-B", "-n")
SCRIPT_EXT = (".py", ".sh", ".js")
SHELL_META = set('|&;$`<>(){}!*?#~\\"\'')
REF = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._/-]*$")


def rows_of(text):
    """Yield (line number, key, value); None for the line number of a malformed line.

    A key may be written as in a markdown list or in bold: `- base-branch`,
    `**base-branch**` and a backticked key are read as `base-branch`.
    """
    for n, raw in enumerate(text.splitlines(), 1):
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        if ":" not in s:
            yield n, None, None
            continue
        key, value = s.split(":", 1)
        key = key.strip().lower()
        if key.startswith(("- ", "* ")):
            key = key[2:]
        key = key.strip().strip("*`").strip()
        yield n, key, value.strip()


def refused_key(key):
    key = key.lower()
    return any(word in key for word in REFUSED)


def shown(value):
    """The bad value as it appears in the status line, cut so it cannot flood a comment."""
    if not value:
        return "empty"
    return value if len(value) <= 60 else value[:57] + "..."


def refused_value(value):
    low = value.lower()
    return any(p in low for p in OUTBOUND + CREDENTIAL)


def ok_ref(value):
    return bool(REF.match(value)) and ".." not in value and "//" not in value \
        and not value.endswith("/")


def safe_path(token):
    """A token that cannot leave the repository, including through --out=/elsewhere."""
    for part in token.split("="):
        if part.startswith("/") or "~" in part or ".." in part.split("/"):
            return False
    return True


def ok_check(value, root):
    """True when the command runs one repository script through a known interpreter."""
    if not value or any(c in value for c in SHELL_META):
        return False
    argv = value.split()
    if argv[0] not in INTERPRETERS:
        return False
    rest = argv[1:]
    while rest and rest[0] in FLAGS:
        rest = rest[1:]
    if not rest:
        return False
    script = rest[0]
    if not safe_path(script) or not script.endswith(SCRIPT_EXT):
        return False
    try:
        inside = (root / script).resolve().is_relative_to(root.resolve())
    except OSError:
        return False
    return inside and all(safe_path(a) for a in rest[1:])


def read(root):
    path = root / FILE
    if not path.is_file():
        return ["PROJECT-OK", "SETTINGS-NONE"], 0
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        return [f"PROJECT-BAD-VALUE {FILE} ({e.strerror})"], 1

    parsed, refused, checks, values, unknown, seen = [], [], [], [], [], {}
    for n, key, value in rows_of(text):
        if key is None:
            return [f"PROJECT-BAD-VALUE line {n} (not key: value)"], 1
        if refused_key(key):
            refused.append(key)
            continue
        if key not in ALLOWED:
            unknown.append(key)
            continue
        if key in SINGLE:
            seen[key] = seen.get(key, 0) + 1
            if seen[key] > 1:
                values.append((key, f"set {seen[key]} times"))
                continue
        if key == "checks" and not ok_check(value, root):
            checks.append(key)
            continue
        if key == "rules" and refused_key(value):
            refused.append(key)
            continue
        if not value or refused_value(value) or (key in SINGLE and not ok_ref(value)):
            values.append((key, value))
            continue
        parsed.append((key, value))

    if refused:
        return [f"PROJECT-REFUSED {refused[0]}"], 1
    if checks:
        return [f"PROJECT-CHECK-REFUSED {checks[0]}"], 1
    if values:
        return [f"PROJECT-BAD-VALUE {values[0][0]} ({shown(values[0][1])})"], 1
    status = [f"PROJECT-UNKNOWN-KEY {unknown[0]}"] if unknown else ["PROJECT-OK"]
    body = [f"SETTING {k}={v}" for k, v in parsed] + [f"IGNORED {k}" for k in unknown]
    return status + (body or ["SETTINGS-NONE"]), 0


def main(argv):
    root = pathlib.Path(argv[1] if len(argv) > 1 else ".")
    lines, code = read(root)
    print("\n".join(lines))
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv))
