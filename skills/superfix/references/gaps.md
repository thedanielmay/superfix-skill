# Gap notes

New in 1.4.1 ([superfix-skill#51](https://github.com/thedanielmay/superfix-skill/issues/51), design in [superfix-skill#39](https://github.com/thedanielmay/superfix-skill/issues/39)). SKILL.md (Coverage check) says when to read this file: before the first gap note of a run. A gap note records a KIND of problem Superfix does not cover yet, and what a playbook for it would need. It never records the owner's problem itself. Superfix never edits itself because of a note. Every command writes its values out literally (the shell keeps no variables between calls) and prints one word: silence is never a pass.

### Which problems get a note

- Every "Everything else" problem with no checkable criterion (Superfix could not draft one and the owner gave none), which stops at diagnosis, and every criterion Superfix had no tool or access to check, so it fell to later or owner.
- A Code or Qik problem whose diagnosis fell to low confidence because its row's own tools were missing (partial). For Qik that means the Qik read tools were missing; a Qik problem is not partial otherwise.
- When: at the Stop gate, before the decision comment. This is a write before approval, allowed by SKILL.md Phase 1.
- One note per kind of problem per run.

### What a note holds, and never holds

Holds the KIND only:
- Title: `[gap] <kind of problem>: <generic short name>`, one line, for example `[gap] document: confusing step by step guide`.
- Body, in this order:

```
> **In plain English:** Superfix met a kind of problem it does not cover: <kind, in plain words>. This note says what a playbook for it would need.

Kind of problem: <generic>
Coverage row: <Everything else (no checkable criterion) | Everything else (criterion not checkable) | Code, partial (tools missing) | Qik, partial (read tools missing)>
Why it stopped at diagnosis: <generic>
What was tried: <tools and steps, generic>
What a playbook would need: recognisers (<words or signs>); evidence (<what to collect>); failing check form (<how to show it fails>); what done means (<generic>); tools (<generic>)
Confidence: <low | medium>
Superfix version: 1.5.0
```

Never holds: a quote or paraphrase of the owner's request, a client, repo, organisation or person name, a path, a URL, an e-mail address, code, a secret, a picture or a diagram. Write it so a stranger could read it without learning whose problem it was. Avoid `/` altogether (the check below flags `word/word`).

Write three files under `umask 077`, each with a quoted heredoc (`cat > <file> <<'EOF'`), never with `echo "..."`: `$HOME/.superfix/runs/<run-key>/gap-<k>-title.txt`, `$HOME/.superfix/runs/<run-key>/gap-<k>-body.md` and `$HOME/.superfix/runs/<run-key>/gap-<k>-kind.txt` (the kind of problem alone, one line; `<k>` = 1, 2, ... in this run).

The kind file is used in searches, so it may hold only letters, digits, spaces, commas and hyphens, and must start with a letter or digit (no `:`, so it cannot become a search qualifier such as `user:x`; no leading `-`, so it cannot become `-label:y`):

```bash
KF="$HOME/.superfix/runs/<run-key>/gap-<k>-kind.txt"; if [ "$(wc -l < "$KF" | tr -d ' ')" = 1 ] && grep -qxE '[A-Za-z0-9][A-Za-z0-9 ,-]*' "$KF"; then echo GAP-KIND-OK; else echo GAP-KIND-BAD; fi
```

`GAP-KIND-BAD`: write the kind again in plain words and run it again.

### 1. Note check (normalise, then redact; before anything else)

It writes a normalised copy of each file (entities decoded, zero-width and direction characters removed, lines joined), runs the exact-string check on all four files, then the names check, then the pattern check extended with `/Users/` and `~/` paths, e-mail addresses, any URL and `owner/repo`-looking strings.

- The names check reads the note and every name with `-`, `_` and spaces collapsed to one space, ignoring case. The names: the work repo's owner login and repo name, the run key (with the file-mode slug), and `XN`: the issue author's login, the owner's display name when known, and the Qik organisation name when the coverage row is Qik (comma separated, or `none`). It blocks each whole name (also written without spaces), and each word of 3 or more letters in them, except dates, numbers and the fixed words of the note template ("superfix", "version", "problem" and the like). So repo `vce-exam-engine` blocks "the VCE exam-engine docs", "the vce_exam engine" and "the exam engine", and slug `2026-10-19-alison-fiske-booking` blocks "the Alison Fiske booking form". The issue number is blocked only as `#51`, `issue 51` or `issue #51` (a `.` or `,` after it still counts), so "step 3 fails" passes. `W` is the work repo (`none/none` without a remote) and `IN` the issue number (`none` without an issue).
- Honest limit: a client name that appears nowhere in these sources is covered only by the writing rule above.

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; K='<k>'; W='<work owner>/<work repo>'; RK='<run-key>'; IN='<issue number, or none>'; XN='<issue author login, owner display name, Qik organisation (Qik row only); comma separated, or none>'; T="$D/gap-$K-title.txt"; F="$D/gap-$K-body.md"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; exit 1; elif [ ! -s "$T" ] || [ ! -s "$F" ]; then echo "GAP-NOTE-BLOCKED missing"; exit 1; elif ! M="$(python3 -I -c 'import html, re, sys
zw = re.compile("[\u00ad\u200b-\u200f\u2060\ufeff\u202a-\u202e]")
w, rk, n, xn = sys.argv[1:5]
norm = lambda t: re.sub(r"[-_\s]+", " ", t.lower()).strip()
stop = set("superfix version kind problem problems coverage row everything else covered code partial tools tool missing qik read why stopped diagnosis what was tried playbook would need needs recognisers evidence failing check form done means confidence low medium plain english met does not cover this note says the and for with gap".split())
whole, words = set(), set()
for x in w.split("/") + [w.replace("/", " ")] + rk.split("+") + [rk] + xn.split(","):
    x = norm(x)
    if not x or x == "none" or re.fullmatch(r"[\d ]+", x):
        continue
    whole |= {x, x.replace(" ", "")}
    words |= {t for t in x.split() if len(t) >= 3 and not t.isdigit() and t not in stop}
hit = False
for f in sys.argv[5:]:
    s = re.sub(r"\s+", " ", zw.sub("", html.unescape(open(f, encoding="utf-8", errors="replace").read())))
    open(f + ".norm", "w").write(s + "\n")
    lo = norm(s)
    for x in whole | words:
        if re.search(r"(?<![a-z0-9])" + re.escape(x) + r"(?![a-z0-9])", lo) or (len(x) >= 5 and " " not in x and x in lo.replace(" ", "")):
            hit = True
    if n.isdigit() and re.search(r"(?<!\w)(?:#|issue\s+#?)" + n + r"(?!\w)", s, re.I):
        hit = True
print("NAMES-HIT" if hit else "NAMES-CLEAN")' "$W" "$RK" "$IN" "$XN" "$T" "$F")"; then echo "GAP-NOTE-BLOCKED normalise"; exit 1; else X="$(P="$(grep -v '^[[:space:]]*$' "$D/secrets" 2>/dev/null)"; if [ -z "$P" ]; then echo NO-LIST; else H="$(printf '%s\n' "$P" | grep -F -l -f - "$T" "$F" "$T.norm" "$F.norm")"; rc=$?; if [ $rc -gt 1 ]; then echo ERROR; elif [ -n "$H" ]; then echo BLOCKED; else echo CLEAN; fi; fi)"; H="$( { grep -H -n -E -i '(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' "$T" "$F" "$T.norm" "$F.norm"; grep -H -n -E '(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|-----BEGIN [A-Z ]*KEY-----|://[^/[:space:]:@]+:[^/[:space:]@]+@|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|/Users/|~/|[A-Za-z][A-Za-z0-9+.-]*://|www\.|[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9._-]*[A-Za-z0-9]' "$T" "$F" "$T.norm" "$F.norm"; perl -ne 'while (/(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])/g) { my $s=$1; next unless $s=~/[A-Za-z]/ && $s=~/[0-9]/; print "$ARGV:$.:\n" } close ARGV if eof' "$T" "$F" "$T.norm" "$F.norm"; } | cut -d: -f1,2 | sort -u )"; case "$X" in CLEAN|NO-LIST) if [ "$M" != NAMES-CLEAN ]; then echo "GAP-NOTE-BLOCKED names (the work repo's owner or name, the run key or the issue number is in the note; rewrite it generically)"; exit 1; elif [ -n "$H" ]; then echo "GAP-NOTE-BLOCKED pattern (file:line; rewrite the note generically, then run this again):"; echo "$H"; exit 1; else echo GAP-NOTE-CLEAN; fi;; BLOCKED) echo "GAP-NOTE-BLOCKED exact"; exit 1;; *) echo "GAP-NOTE-BLOCKED exact (the check did not run)"; exit 1;; esac; fi
```

- `GAP-NOTE-CLEAN`: go on.
- `GAP-NOTE-BLOCKED <exact|names|pattern|missing|normalise>`: rewrite the note more generically and run the check again. A second block sends the note to the local folder (step 4), never to a repo; a block a third time: write no note and say `Gap note: NONE (the note could not be made generic)`. Hits block; there is no "you decide" for gap notes.

### 2. The gap repo check (every check must pass)

The repo is named by the line `gap_repo=<owner>/<repo>` in `~/.superfix/config` (read with `grep`, never `source`), or by the environment variable `SUPERFIX_GAP_REPO`. It is never hard-coded and never the work repo.

- **Who may choose the repo:** only the owner, in `~/.superfix/config` or his own shell environment. A project setting (for example a work repo's `.claude/settings.json` setting `SUPERFIX_GAP_REPO`) must never redirect notes. A run cannot tell where an environment variable came from, so the variable is treated as untrusted: notes go to the repo it names only when `~/.superfix/config` also holds the owner's dated line for that same repo (below). Without that line the check says `GAP-REPO-APPS-UNCHECKED` and the note stays local.
- **What cannot be defended mechanically:** a project's `.claude/settings.json` or direnv can also set `HOME` (and so which `~/.superfix/config` is read), `GH_TOKEN` (and so which account `gh` acts as) or `SUPERFIX_GAP_REPO`. No check here can tell. What could leak is only the generic note itself, and the attestation line names the one repo the owner checked.
- **GitHub Apps cannot be checked with the `gh` login** (`gh api user/installations` answers 403, `repos/<o>/<r>/installation` 401). The owner checks them himself: he opens https://github.com/settings/installations, makes sure no App can read the gap repo, and then adds this line to `~/.superfix/config`, with the repo and today's date:

```
gap_repo_no_apps=<owner>/<gap repo> <YYYY-MM-DD>
```

  The check needs a line for exactly the chosen repo (any case), dated within the last 90 days and not in the future. An older form without the repo name (`gap_repo_no_apps=<date>`), another repo, or an old date: `GAP-REPO-APPS-UNCHECKED`. Superfix never writes this line.
- **Workflows in the gap repo** are scanned like the `assets` check in evidence.md, with quotes and YAML anchors removed first: any workflow file whose text holds `issues`, `label`, `push`, `release`, `create`, `tags`, `workflow_run`, `workflow_call` or `repository_dispatch`, or writes `on:` in flow syntax, or cannot be read (`UNREAD`), prints `GAP-REPO-WORKFLOWS` and the note stays local.

```bash
W='<work owner>/<work repo>'; G="${SUPERFIX_GAP_REPO:-$(grep -E '^gap_repo=' "$HOME/.superfix/config" 2>/dev/null | tail -1 | cut -d= -f2-)}"; ME="$(gh api user -q .login)"; if [ -z "$G" ]; then echo GAP-REPO-UNSET; elif ! printf '%s\n' "$G" | grep -qE '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$'; then echo GAP-REPO-BAD-NAME; elif [ "$(printf '%s' "$G" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$W" | tr '[:upper:]' '[:lower:]')" ]; then echo "GAP-REPO-REFUSED the gap repo is the work repo"; elif ! V="$(gh repo view "$G" --json visibility,owner -q '.visibility + " " + .owner.login')"; then echo "GAP-REPO-MISSING $G"; elif [ -z "$ME" ] || [ "${V#* }" != "$ME" ]; then echo "GAP-REPO-NOT-OWNED $G"; elif [ "${V%% *}" != PRIVATE ]; then echo "GAP-REPO-NOT-PRIVATE $G"; elif [ "$(gh api "repos/$G/collaborators" -q '[.[].login] | join(",")')" != "$ME" ]; then echo "GAP-REPO-SHARED $G (someone else can read it, or the list could not be read)"; elif [ "$(gh api "repos/$G/hooks" -q length)" != 0 ]; then echo "GAP-REPO-HOOKS $G (a webhook, or the hook list could not be read)"; else FL="$(L="$(gh api "repos/$G/git/trees/HEAD?recursive=1" -q 'if .truncated then "TRUNCATED" else (.tree[] | select(.type == "blob") | .path) end' 2>&1)"; rc=$?; if [ $rc -ne 0 ] && ! printf '%s\n' "$L" | grep -q 'HTTP 409'; then echo "UNREAD the file list could not be read"; elif [ $rc -eq 0 ]; then printf '%s\n' "$L" | grep -qx TRUNCATED && echo "UNREAD the file list is too long to read in full"; printf '%s\n' "$L" | grep -i '^\.github/workflows/' | while IFS= read -r p; do C="$(gh api "repos/$G/contents/$p" -q .content 2>/dev/null | base64 -d 2>/dev/null)"; if [ -z "$C" ]; then echo "UNREAD $p"; elif printf '%s\n' "$C" | sed -e "s/[\"']//g" -e 's/[&*][A-Za-z0-9_-]*//g' | grep -qiE 'issues|label|push|release|create|tags|workflow_run|workflow_call|repository_dispatch|(^|[[:space:]])on:[[:space:]]*[[{]'; then echo "FLAG $p"; fi; done; fi)"; if [ -n "$FL" ]; then echo "GAP-REPO-WORKFLOWS $G"; printf '%s\n' "$FL"; else A="$(awk -v g="$(printf '%s' "$G" | tr '[:upper:]' '[:lower:]')" '/^gap_repo_no_apps=/ { n = split(substr($0, 18), f, " "); if (n == 2 && tolower(f[1]) == g && f[2] ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) d = f[2] } END { print d }' "$HOME/.superfix/config" 2>/dev/null)"; TS="$(date -j -f %Y-%m-%d "$A" +%s 2>/dev/null)"; NOW="$(date +%s)"; if [ -z "$TS" ] || [ "$TS" -gt "$NOW" ] || [ $((NOW - TS)) -gt 7776000 ]; then echo "GAP-REPO-APPS-UNCHECKED $G (no gap_repo_no_apps=$G <date> line within 90 days in ~/.superfix/config)"; else echo "GAP-REPO-OK $G"; fi; fi; fi
```

- `W` is the work repo; a file-mode run with no remote writes `W='none/none'`.
- What it checks, in order: the name is valid; it is not the work repo (`GAP-REPO-REFUSED`); it exists; the signed-in user owns it; it is PRIVATE; its collaborators list is exactly the owner; it has no webhook; no workflow could react (`GAP-REPO-WORKFLOWS`, with `FLAG` and `UNREAD` lines); the owner's dated line names this repo.
- `GAP-REPO-OK <repo>`: file to that repo (step 3). Any other word: the local folder (step 4). None of them is a reason to stop the run.

### 3. Filing in the gap repo (only after GAP-REPO-OK)

De-duplicate first, in a new call, with the checked kind file (search can lag a few minutes behind a new note; that is a known limit):

```bash
G='<gap repo>'; KF="$HOME/.superfix/runs/<run-key>/gap-<k>-kind.txt"; if S="$(gh issue list --repo "$G" --state open --label superfix:gap --search "\"$(cat "$KF")\" in:title" --limit 10 --json number,title -q '.[] | "\(.number) \(.title)"')"; then if [ -n "$S" ]; then echo GAP-CANDIDATES; printf '%s\n' "$S"; else echo GAP-NO-MATCH; fi; else echo GAP-SEARCH-FAILED; fi
```

- A candidate is the same note only when its kind AND two distinct key words of its title match yours. Then post a "Seen again" comment. Its text is made by the command, not written by you: the date only, so it can hold no name (1.4.1 dropped the run-key hash it used to carry):

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; G='<gap repo>'; I='<note number>'; S="$D/gap-seen.md"; printf 'Seen again: %s\n' "$(date +%Y-%m-%d)" > "$S" && if gh issue comment "$I" --repo "$G" --body-file "$S" >/dev/null; then echo "GAP-SEEN-AGAIN $I"; else echo GAP-FILE-FAILED; fi
```

- Otherwise a new note. Only now, after `GAP-REPO-OK`, add one line to the end of the body file: `Source: [<repo>#<N>](https://github.com/<owner>/<repo>/issues/<N>)` (the work issue). This is the one place the work repo is named, and only in the private gap repo. Then run both redaction.md checks (exact-string and pattern) on the title and body files: `CLEAN` or `NO-LIST`, and `PATTERN-CLEAN`.
- Make sure the gap label exists with the label ensure command from journal.md (Labels), with `R` the gap repo, `L='superfix:gap'`, `C='5319E7'`, `T='A kind of problem Superfix does not cover yet'`.
- Create it:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; G='<gap repo>'; K='<k>'; if U="$(gh issue create --repo "$G" --title "$(cat "$D/gap-$K-title.txt")" --body-file "$D/gap-$K-body.md" --label superfix:gap)"; then echo "GAP-FILED $U"; else echo GAP-FILE-FAILED; fi
```

- `GAP-FILE-FAILED` or `GAP-SEARCH-FAILED`: write the note to the local folder instead (step 4); that command leaves the `Source:` line out.

### 4. The local folder (any word but GAP-REPO-OK, or a failed filing)

The note is written WITHOUT any `Source:` line (the command leaves it out, also after a failed filing) and with no run key or hash of it. Search first, with the checked kind file:

```bash
Q="$HOME/.superfix/gaps"; KF="$HOME/.superfix/runs/<run-key>/gap-<k>-kind.txt"; if [ ! -d "$Q" ]; then echo GAP-NO-MATCH; else S="$(find "$Q" -maxdepth 1 -name '*.md' | while IFS= read -r f; do printf '%s %s\n' "$f" "$(head -1 "$f")"; done | grep -i -F -f "$KF")"; if [ -n "$S" ]; then echo GAP-CANDIDATES; printf '%s\n' "$S"; else echo GAP-NO-MATCH; fi; fi
```

- Same rule as above: kind AND two key words match: `umask 077; printf '\nSeen again: %s\n' "$(date +%Y-%m-%d)" >> '<that file>' && echo "GAP-SEEN-AGAIN <that file>"`.
- Otherwise a new file, mode 600 in a folder of mode 700:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; K='<k>'; Q="$HOME/.superfix/gaps"; F="$Q/<YYYY-MM-DD>-<slug>.md"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ -e "$F" ]; then echo "GAP-LOCAL-EXISTS $F"; else mkdir -p "$Q" && chmod 700 "$Q" && { cat "$D/gap-$K-title.txt"; echo; grep -v '^Source: ' "$D/gap-$K-body.md"; } > "$F" && chmod 600 "$F" && echo "GAP-LOCAL $F"; fi
```

- `GAP-LOCAL-EXISTS`: use a new slug, or Seen again on that file.

### On the work issue

- The gap repo's name and link appear in a work-repo comment only when the work repo is PRIVATE and its collaborators are only the owner. Check once per run:

```bash
W='<owner>/<repo>'; ME="$(gh api user -q .login)"; if [ -n "$ME" ] && [ "$(gh repo view "$W" --json visibility -q .visibility)" = PRIVATE ] && [ "$(gh api "repos/$W/collaborators" -q '[.[].login] | join(",")')" = "$ME" ]; then echo GAP-LINK-OK; else echo GAP-LINK-HIDDEN; fi
```

- The decision comment, below the numbered questions, one line per noted problem:
  - `GAP-LINK-OK` and `GAP-FILED` or `GAP-SEEN-AGAIN`: `P<k> (problem <k>: <short name>) is outside what I cover, so I noted it in your private gap list: [<gap repo name>#<n>](<link>). All notes, most seen first: https://github.com/<gap repo>/issues?q=is%3Aopen+sort%3Acomments-desc`
  - `GAP-LINK-HIDDEN` (a public work repo, or one shared with anyone else): `... so I noted it in your private gap list.` with no name, no link and no list link.
  - Local: `... so I wrote a gap note on the owner's Mac (~/.superfix/gaps/).`
- AI detail, required (journal.md): `Gap note: FILED <n> | SEEN-AGAIN <n> | LOCAL <n> | NONE (supported)`, adding the repo words, for example `Gap note: LOCAL 1 (GAP-REPO-APPS-UNCHECKED)`. With `GAP-LINK-HIDDEN` the AI detail names no gap repo either.
- The final comment's `Gap note:` line adds the open count. Gap repo: `G='<gap repo>'; if C="$(gh issue list --repo "$G" --state open --label superfix:gap --limit 1000 --json number -q length)"; then echo "GAP-OPEN $C"; else echo GAP-SEARCH-FAILED; fi`. Local: `find "$HOME/.superfix/gaps" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' '`, read as `GAP-OPEN <n>`. The line reads `Gap note: FILED 1 (at the stop); open notes in your gap list: <n>`.
- On restart, search (steps 3 and 4) before filing any note, so a note is never filed twice.
- Superfix never edits this skill because of a gap note; the owner reads the list and decides.
