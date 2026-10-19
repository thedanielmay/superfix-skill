# Gap notes

New in 1.4.1 ([superfix-skill#51](https://github.com/thedanielmay/superfix-skill/issues/51), design in [superfix-skill#39](https://github.com/thedanielmay/superfix-skill/issues/39)). SKILL.md (Coverage check) says when to read this file: before the first gap note of a run. A gap note records a KIND of problem Superfix does not cover yet, and what a playbook for it would need. It never records the owner's problem itself. Superfix never edits itself because of a note. Every command writes its values out literally (the shell keeps no variables between calls) and prints one word: silence is never a pass.

### Which problems get a note

- Every problem whose Coverage line is "Everything else" (not covered).
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
Coverage row: <Everything else (not covered) | Code, partial (tools missing) | Qik, partial (read tools missing)>
Why it stopped at diagnosis: <generic>
What was tried: <tools and steps, generic>
What a playbook would need: recognisers (<words or signs>); evidence (<what to collect>); failing check form (<how to show it fails>); what done means (<generic>); tools (<generic>)
Confidence: <low | medium>
Superfix version: 1.4.1
```

Never holds: a quote or paraphrase of the owner's request, a client, repo, organisation or person name, a path, a URL, an e-mail address, code, a secret, a picture or a diagram. Write it so a stranger could read it without learning whose problem it was. Avoid `/` altogether (the check below flags `word/word`).

Write the two files under `umask 077`: `$HOME/.superfix/runs/<run-key>/gap-<k>-title.txt` and `$HOME/.superfix/runs/<run-key>/gap-<k>-body.md` (`<k>` = 1, 2, ... in this run).

### 1. Note check (normalise, then redact; before anything else)

It writes a normalised copy of each file (entities decoded, zero-width and direction characters removed, lines joined), runs the exact-string check on all four files, and the pattern check extended with `/Users/` and `~/` paths, e-mail addresses, any URL and `owner/repo`-looking strings:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; K='<k>'; T="$D/gap-$K-title.txt"; F="$D/gap-$K-body.md"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ ! -s "$T" ] || [ ! -s "$F" ]; then echo "GAP-NOTE-BLOCKED missing"; elif ! python3 -I -c 'import html, re, sys
zw = re.compile("[­​-‏⁠﻿‪-‮]")
for f in sys.argv[1:]:
    s = zw.sub("", html.unescape(open(f, encoding="utf-8", errors="replace").read()))
    open(f + ".norm", "w").write(re.sub(r"\s+", " ", s) + "\n")' "$T" "$F"; then echo "GAP-NOTE-BLOCKED normalise"; else X="$(P="$(grep -v '^[[:space:]]*$' "$D/secrets" 2>/dev/null)"; if [ -z "$P" ]; then echo NO-LIST; else H="$(printf '%s\n' "$P" | grep -F -l -f - "$T" "$F" "$T.norm" "$F.norm")"; rc=$?; if [ $rc -gt 1 ]; then echo ERROR; elif [ -n "$H" ]; then echo BLOCKED; else echo CLEAN; fi; fi)"; H="$( { grep -H -n -E -i '(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' "$T" "$F" "$T.norm" "$F.norm"; grep -H -n -E '(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|-----BEGIN [A-Z ]*KEY-----|://[^/[:space:]:@]+:[^/[:space:]@]+@|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|/Users/|~/|[A-Za-z][A-Za-z0-9+.-]*://|www\.|[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9._-]*[A-Za-z0-9]' "$T" "$F" "$T.norm" "$F.norm"; perl -ne 'while (/(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])/g) { my $s=$1; next unless $s=~/[A-Za-z]/ && $s=~/[0-9]/; print "$ARGV:$.:\n" } close ARGV if eof' "$T" "$F" "$T.norm" "$F.norm"; } | cut -d: -f1,2 | sort -u )"; case "$X" in CLEAN|NO-LIST) if [ -n "$H" ]; then echo "GAP-NOTE-BLOCKED pattern (file:line; rewrite the note generically, then run this again):"; echo "$H"; else echo GAP-NOTE-CLEAN; fi;; BLOCKED) echo "GAP-NOTE-BLOCKED exact";; *) echo "GAP-NOTE-BLOCKED exact (the check did not run)";; esac; fi
```

- `GAP-NOTE-CLEAN`: go on.
- `GAP-NOTE-BLOCKED <exact|pattern|missing|normalise>`: rewrite the note more generically and run the check again. A second block sends the note to the local folder (step 4), never to a repo; a block a third time: write no note and say `Gap note: NONE (the note could not be made generic)`. Pattern hits block; there is no "you decide" for gap notes.

### 2. The gap repo check (every check must pass)

The repo is named by the environment variable `SUPERFIX_GAP_REPO`, else the line `gap_repo=<owner>/<repo>` in `~/.superfix/config` (read with `grep`, never `source`). It is never hard-coded and never the work repo.

```bash
W='<work owner>/<work repo>'; G="${SUPERFIX_GAP_REPO:-$(grep -E '^gap_repo=' "$HOME/.superfix/config" 2>/dev/null | tail -1 | cut -d= -f2-)}"; ME="$(gh api user -q .login)"; if [ -z "$G" ]; then echo GAP-REPO-UNSET; elif ! printf '%s\n' "$G" | grep -qE '^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$'; then echo GAP-REPO-BAD-NAME; elif [ "$(printf '%s' "$G" | tr '[:upper:]' '[:lower:]')" = "$(printf '%s' "$W" | tr '[:upper:]' '[:lower:]')" ]; then echo "GAP-REPO-REFUSED the gap repo is the work repo"; elif ! V="$(gh repo view "$G" --json visibility,owner -q '.visibility + " " + .owner.login')"; then echo "GAP-REPO-MISSING $G"; elif [ -z "$ME" ] || [ "${V#* }" != "$ME" ]; then echo "GAP-REPO-NOT-OWNED $G"; elif [ "${V%% *}" != PRIVATE ]; then echo "GAP-REPO-NOT-PRIVATE $G"; elif [ "$(gh api "repos/$G/collaborators" -q '[.[].login] | join(",")')" != "$ME" ]; then echo "GAP-REPO-SHARED $G (someone else can read it, or the list could not be read)"; elif [ "$(gh api "repos/$G/hooks" -q length)" != 0 ]; then echo "GAP-REPO-HOOKS $G (a webhook, or the hook list could not be read)"; else A="$(grep -E '^gap_repo_no_apps=[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$HOME/.superfix/config" 2>/dev/null | tail -1 | cut -d= -f2)"; T="$(date -j -f %Y-%m-%d "$A" +%s 2>/dev/null)"; NOW="$(date +%s)"; if [ -z "$T" ] || [ "$T" -gt "$NOW" ] || [ $((NOW - T)) -gt 7776000 ]; then echo "GAP-REPO-APPS-UNCHECKED $G (no gap_repo_no_apps= date within 90 days in ~/.superfix/config)"; else echo "GAP-REPO-OK $G"; fi; fi
```

- `W` is the work repo; a file-mode run with no remote writes `W='none/none'`.
- What it checks: the name is valid; it is not the work repo (`GAP-REPO-REFUSED`); it exists; the signed-in user owns it; it is PRIVATE; its collaborators list is exactly the owner; it has no webhook; and the owner's dated line (below).
- **GitHub Apps cannot be checked with the `gh` login** (`gh api user/installations` answers 403, `repos/<o>/<r>/installation` 401). So the last check passes only when `~/.superfix/config` has a line `gap_repo_no_apps=<YYYY-MM-DD>`, dated within the last 90 days, written by the owner himself after he looked at https://github.com/settings/installations and saw that no App can read the gap repo. Superfix never writes that line.
- `GAP-REPO-OK <repo>`: file to that repo (step 3). Any other word: the local folder (step 4). `NOT-PRIVATE` and the others are never a reason to stop the run.

### 3. Filing in the gap repo (only after GAP-REPO-OK)

De-duplicate first, in a new call (search can lag a few minutes behind a new note; that is a known limit):

```bash
G='<gap repo>'; if S="$(gh issue list --repo "$G" --state open --label superfix:gap --search "<kind> in:title" --limit 10 --json number,title -q '.[] | "\(.number) \(.title)"')"; then if [ -n "$S" ]; then echo GAP-CANDIDATES; printf '%s\n' "$S"; else echo GAP-NO-MATCH; fi; else echo GAP-SEARCH-FAILED; fi
```

- A candidate is the same note only when its kind AND two distinct key words of its title match yours. Then write `Seen again: <YYYY-MM-DD>, run <run-key>` to `$HOME/.superfix/runs/<run-key>/gap-seen-<k>.md`, run both redaction.md checks on it, and post it: `if gh issue comment <number> --repo '<gap repo>' --body-file "$HOME/.superfix/runs/<run-key>/gap-seen-<k>.md" >/dev/null; then echo "GAP-SEEN-AGAIN <number>"; else echo GAP-FILE-FAILED; fi`.
- Otherwise a new note. Only now, after `GAP-REPO-OK`, add one line to the end of the body file: `Source: [<repo>#<N>](https://github.com/<owner>/<repo>/issues/<N>)` (the work issue, or the run key when there is no issue). Then run both redaction.md checks (exact-string and pattern) on the title and body files: `CLEAN` or `NO-LIST`, and `PATTERN-CLEAN`.
- Make sure the gap label exists with the label ensure command from journal.md (Labels), with `R` the gap repo, `L='superfix:gap'`, `C='5319E7'`, `T='A kind of problem Superfix does not cover yet'`.
- Create it:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; G='<gap repo>'; K='<k>'; if U="$(gh issue create --repo "$G" --title "$(cat "$D/gap-$K-title.txt")" --body-file "$D/gap-$K-body.md" --label superfix:gap)"; then echo "GAP-FILED $U"; else echo GAP-FILE-FAILED; fi
```

- `GAP-FILE-FAILED` or `GAP-SEARCH-FAILED`: write the note to the local folder instead (step 4).

### 4. The local folder (any word but GAP-REPO-OK, or a failed filing)

The note is written WITHOUT the source link; the run key goes at the end instead. Search first:

```bash
Q="$HOME/.superfix/gaps"; if [ ! -d "$Q" ]; then echo GAP-NO-MATCH; else S="$(find "$Q" -maxdepth 1 -name '*.md' | while IFS= read -r f; do printf '%s %s\n' "$f" "$(head -1 "$f")"; done | grep -i -F '<kind>')"; if [ -n "$S" ]; then echo GAP-CANDIDATES; printf '%s\n' "$S"; else echo GAP-NO-MATCH; fi; fi
```

- Same rule as above: kind AND two key words match: `umask 077; printf '\nSeen again: %s, run %s\n' '<YYYY-MM-DD>' '<run-key>' >> '<that file>' && echo "GAP-SEEN-AGAIN <that file>"`.
- Otherwise a new file, mode 600 in a folder of mode 700:

```bash
umask 077; D="$HOME/.superfix/runs/<run-key>"; K='<k>'; Q="$HOME/.superfix/gaps"; F="$Q/<YYYY-MM-DD>-<slug>.md"; if [ ! -f "$D/key" ]; then echo "NO-RUN-FOLDER $D"; elif [ -e "$F" ]; then echo "GAP-LOCAL-EXISTS $F"; else mkdir -p "$Q" && chmod 700 "$Q" && { cat "$D/gap-$K-title.txt"; echo; cat "$D/gap-$K-body.md"; printf '\nRun key: %s\n' '<run-key>'; } > "$F" && chmod 600 "$F" && echo "GAP-LOCAL $F"; fi
```

- `GAP-LOCAL-EXISTS`: use a new slug, or Seen again on that file.

### On the work issue

- The decision comment, below the numbered questions, one line per noted problem:
  - PRIVATE work repo and `GAP-FILED` or `GAP-SEEN-AGAIN`: `P<k> (problem <k>: <short name>) is outside what I cover, so I noted it in your private gap list: [<gap repo name>#<n>](<link>). All notes, most seen first: https://github.com/<gap repo>/issues?q=is%3Aopen+sort%3Acomments-desc`
  - PUBLIC work repo: `... so I noted it in your private gap list.` with no link and no list link (the gap repo's name stays off a public page).
  - Local: `... so I wrote a gap note on the owner's Mac (~/.superfix/gaps/).`
- AI detail, required (journal.md): `Gap note: FILED <n> | SEEN-AGAIN <n> | LOCAL <n> | NONE (supported)`, adding the repo words, for example `Gap note: LOCAL 1 (GAP-REPO-APPS-UNCHECKED)`.
- The final comment's `Gap note:` line adds the open count. Gap repo: `G='<gap repo>'; if C="$(gh issue list --repo "$G" --state open --label superfix:gap --limit 1000 --json number -q length)"; then echo "GAP-OPEN $C"; else echo GAP-SEARCH-FAILED; fi`. Local: `find "$HOME/.superfix/gaps" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' '`, read as `GAP-OPEN <n>`. The line reads `Gap note: FILED 1 (at the stop); open notes in your gap list: <n>`.
- On restart, search (steps 3 and 4) before filing any note, so a note is never filed twice.
- Superfix never edits this skill because of a gap note; the owner reads the list and decides.
