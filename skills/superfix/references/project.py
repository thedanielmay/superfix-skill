#!/usr/bin/env python3
"""Read <repo>/.superfix/project.md and print the settings Superfix applies.

Usage: python3 references/project.py [REPO]      (REPO defaults to the current folder)

Standard library only. It never runs, expands or fetches anything: it reads one
settings file and judges it. The format and the keys are in references/project.md.

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

With --pr-body <file> --issue <n> it reads closing: from the settings and checks
the PR body instead: CLOSING-OK, or CLOSING-BAD <why> and exit 1.
"""
import configparser, pathlib, re, sys

FILE = ".superfix/project.md"
SINGLE = ("base-branch", "pr-base", "closing", "model", "side-findings")
MULTI = ("checks", "rules", "do-not-edit")
ALLOWED = SINGLE + MULTI
# closing: what the PR body says about the issue.
CLOSING = ("auto", "closes", "refs")
# model: a default for the fix stage only; the policy table can still raise it.
MODELS = ("sonnet", "opus", "default")
# side-findings: what the run does with a finding outside the job. list is the default.
SIDE_FINDINGS = ("list", "file")
CLOSING_WORDS = ("closes", "fixes", "resolves")
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
# The three forms a closing keyword or a refs line may name an issue in. A markdown
# link is not one of them: GitHub does not read it as a closing keyword.
OWNER_REPO = r"[A-Za-z0-9._-]+/[A-Za-z0-9._-]+"
ISSUE = (r"(?:https?://github\.com/(?P<url_repo>" + OWNER_REPO + r")/issues/(?P<url_num>\d+)\b|"
         r"(?P<repo>" + OWNER_REPO + r")#(?P<num>\d+)\b|#(?P<local_num>\d+)\b)")
LINK_FORM = re.compile(
    r"^\s*(%s)\s*:?\s*\[[^\]]*\]\(\s*https?://github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/issues/\d+\s*\)"
    % "|".join(CLOSING_WORDS + ("refs",)),
    re.I)


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
        if key == "closing" and value not in CLOSING:
            values.append((key, value))
            continue
        if key == "model" and value not in MODELS:
            values.append((key, value))
            continue
        if key == "side-findings" and value not in SIDE_FINDINGS:
            values.append((key, value))
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


def body_lines(text):
    """(line number, line) for a PR body, with fenced code blocks dropped."""
    out, fence = [], None
    for n, raw in enumerate(text.splitlines(), 1):
        s = raw.strip()
        if fence is None and s.startswith(("```", "~~~")):
            fence = s[:3]
            continue
        if fence is not None:
            if s.startswith(fence):
                fence = None
            continue
        out.append((n, raw))
    return out


def keyword_hits(lines, words):
    """(line number, repository or None, issue number) for each keyword line that
    names the issue as #<n>, <owner>/<repo>#<n> or
    https://github.com/<owner>/<repo>/issues/<n>."""
    pat = re.compile(r"^\s*(%s)\s*:?\s*%s" % ("|".join(words), ISSUE), re.I)
    out = []
    for n, raw in lines:
        m = pat.match(raw)
        if m:
            out.append((n, m.group("url_repo") or m.group("repo"),
                        int(m.group("url_num") or m.group("num") or m.group("local_num"))))
    return out


def repository_name(root):
    """Read origin's GitHub owner/repository locally, including linked worktrees.

    No Git command or config include is executed. Unknown metadata returns None,
    so a qualified reference cannot pass on its number alone.
    """
    try:
        gitdir = root / ".git"
        if gitdir.is_file():
            marker = gitdir.read_text(encoding="utf-8").strip()
            if not marker.startswith("gitdir: "):
                return None
            gitdir = root / marker[len("gitdir: "):]
        common = gitdir / "commondir"
        if common.is_file():
            gitdir = gitdir / common.read_text(encoding="utf-8").strip()
        config = configparser.ConfigParser(interpolation=None, strict=False)
        config.read(gitdir / "config", encoding="utf-8")
        url = config.get('remote "origin"', "url", fallback="")
    except (OSError, UnicodeError, configparser.Error):
        return None
    match = re.fullmatch(
        r"(?:https?://github\.com/|ssh://git@github\.com/|git@github\.com:)(%s)/?"
        % OWNER_REPO, url, re.I)
    return match.group(1).lower().removesuffix(".git") if match else None


def link_form_hits(lines):
    """(line number) for each line that opens with a keyword and a markdown link. The
    link closes nothing on GitHub, so the checker says so instead of reporting a missing
    keyword the body does not have."""
    return [n for n, raw in lines if LINK_FORM.match(raw)]


def closing_check(root, body_path, issue):
    """The one line verdict for a PR body against the repo's closing: setting."""
    lines, code = read(root)
    if code:
        return [f"CLOSING-BAD settings {lines[0]}"], 1
    wanted = "auto"
    for line in lines:
        if line.startswith("SETTING closing="):
            wanted = line.split("=", 1)[1]
    if not issue or not str(issue).isdigit():
        return ["CLOSING-BAD no-issue"], 1
    path = pathlib.Path(body_path)
    if not path.is_file():
        return ["CLOSING-BAD no-body-file"], 1
    body = body_lines(path.read_text(encoding="utf-8", errors="replace"))
    links = link_form_hits(body)
    if links and wanted in ("closes", "refs"):
        return [f"CLOSING-BAD link-form-does-not-close {links[0]}"], 1
    closes = keyword_hits(body, CLOSING_WORDS)
    refs = keyword_hits(body, ("refs",))
    n = int(issue)
    repository = repository_name(root)
    wrong = [f"{repo}#{num}" if repo and repo.lower() != repository else num
             for _, repo, num in closes
             if num != n or (repo and repo.lower() != repository)]
    if wanted == "closes":
        if not closes:
            return ["CLOSING-BAD no-closing-keyword"], 1
        if wrong:
            return [f"CLOSING-BAD closing-keyword-for {wrong[0]}"], 1
        return ["CLOSING-OK"], 0
    if wanted == "refs":
        if closes:
            return [f"CLOSING-BAD closing-keyword line {closes[0][0]}"], 1
        if not any(num == n and (repo is None or repo.lower() == repository)
                   for _, repo, num in refs):
            return ["CLOSING-BAD no-refs-line"], 1
        return ["CLOSING-OK"], 0
    if wrong:
        return [f"CLOSING-BAD closing-keyword-for {wrong[0]}"], 1
    return ["CLOSING-OK"], 0


def main(argv):
    args = argv[1:]
    body = issue = None
    rest = []
    i = 0
    while i < len(args):
        if args[i] == "--pr-body" and i + 1 < len(args):
            body = args[i + 1]
            i += 2
        elif args[i] == "--issue" and i + 1 < len(args):
            issue = args[i + 1]
            i += 2
        else:
            rest.append(args[i])
            i += 1
    root = pathlib.Path(rest[0] if rest else ".")
    if body is not None:
        lines, code = closing_check(root, body, issue)
        print("\n".join(lines))
        return code
    lines, code = read(root)
    print("\n".join(lines))
    return code


if __name__ == "__main__":
    sys.exit(main(sys.argv))
