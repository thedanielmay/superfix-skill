# Redaction

New in 1.3.0. SKILL.md ("Decision and redaction") says when to run these checks: before ANY push, commit, issue create, comment, body edit, PR create or `--body-file`.

Rules that hold everywhere:
- Every command below is self-contained. Claude Code's shell keeps no variables between Bash calls, so nothing here depends on an earlier command.
- Every check prints one explicit word: `CLEAN`, `BLOCKED <files>`, `NO-LIST`, `PATTERN-CLEAN` or `PATTERN-HITS`. **Silence is never a pass.** No word printed, or an `ERROR` line, means the check did not run: fix it and run it again.
- The exact-string check on session credentials BLOCKS. A pattern hit is REPORTED, and you decide (below).
- Every post uses `--body-file`. Never pass `--body "..."` inline. A `--title` from chat text is written to a file and checked first, then passed as `--title "$(cat <title file>)"`.

### Run folder (one per run, survives a restart)

New in 1.3.1. Each run keeps its credential list and its scratch files in its own folder, `~/.superfix/runs/<run-key>/`, never in a shared file.

- `<run-key>` is built from facts the run already has, so it needs no remembered variable and comes out the same after a restart:
  - With an issue: `<owner>-<repo>-<issue number>`, for example `thedanielmay-superfix-skill-48`.
  - Without an issue: `<owner>-<repo>-<journal file name without .md>`, for example `thedanielmay-superfix-skill-2026-10-19-login-loop`.
  - No remote: the repo folder name in place of `<owner>-<repo>`.
  - A journal run that later creates its issue moves the folder to the issue key (journal.md, the issue question) and uses the issue key from then on.
- Write the literal folder in every command, for example `$HOME/.superfix/runs/thedanielmay-superfix-skill-48`. A variable set in an earlier Bash call is gone.
- The folder is mode 700 and `secrets` in it is mode 600 (created under `umask 077`).
- Two runs on two different issues never share a list: each has its own folder, and the end-of-run step deletes only its own.
- Two runs on the SAME issue at the same time are not supported. They share one folder and one list, and the first to finish deletes the list the other is still using, so the other's check then prints `NO-LIST`.
- The journal files stay in `~/.superfix/journal/`, outside the run folder, and are never deleted by the end-of-run step.

### Session list (a fixed file, survives a restart)

Every exact string the owner gave as a credential, password or token, in any message, plus any found in tool output. One per line. Append with a quoted heredoc, so quotes and `$` survive unchanged:

```bash
D="$HOME/.superfix/runs/<run-key>"; (umask 077; mkdir -p "$D" && chmod 700 "$D" && cat >> "$D/secrets" <<'EOF'
<exact string>
EOF
) && chmod 600 "$D/secrets" && echo LIST-SAVED
```

- The list is a file, so it survives a restart. Blank lines are ignored by the check.
- At the end of the run, delete this run's folder and nothing else. The guard prints `REFUSED` instead of deleting when the path is not one folder inside `~/.superfix/runs/` (an empty key, `..`, or a `/` in the key), so it can never delete `~/.superfix/runs/` itself:

```bash
D="$HOME/.superfix/runs/<run-key>"; K="${D#"$HOME/.superfix/runs/"}"; if [ "$K" = "$D" ] || [ -z "$K" ] || [ "$K" = . ] || [ "$K" = .. ] || [ "$K" != "${K%/*}" ]; then echo "REFUSED: not a run folder: $D"; else rm -rf "$D" && echo LIST-DELETED; fi
```

### Files to check

Body files (comment, issue body, PR body, title file) are checked as they are. After a branch exists, also write the diff and the commit messages to files:

```bash
D="$HOME/.superfix/runs/<run-key>"; (umask 077; mkdir -p "$D") && git diff <approval-sha>..HEAD > "$D/diff" && git log --format=%B <approval-sha>..HEAD > "$D/msgs" && echo FILES-READY
```

`<files>` below means the paths written out in full, for example `~/.superfix/runs/<run-key>/diff ~/.superfix/runs/<run-key>/msgs ~/.superfix/runs/<run-key>/body-<N>.md` (zsh does not split a variable into several file names).

### Exact-string check (blocks; catches a password with no keyword)

```bash
L="$HOME/.superfix/runs/<run-key>/secrets"; P="$(grep -v '^[[:space:]]*$' "$L" 2>/dev/null)"; if [ -z "$P" ]; then echo NO-LIST; else H="$(printf '%s\n' "$P" | grep -F -l -f - <files>)"; rc=$?; if [ $rc -gt 1 ]; then echo "ERROR: a file could not be read"; elif [ -n "$H" ]; then echo "BLOCKED $H"; else echo CLEAN; fi; fi
```

- `CLEAN`: no session credential in those files.
- `BLOCKED <files>`: a session credential is in the named files. Do not post, push or commit. In a comment, body, title or commit message file, replace it with `[redacted]` and run the check again. In the diff (source code), never write `[redacted]`: stop and ask the owner.
- `NO-LIST`: the list file is missing or empty, which means no credential was given this session. Run the pattern check anyway.
- It prints file names only (`-l`), never the matching line, so the secret does not land in the transcript.

### Pattern check (reports; you decide)

```bash
H="$( { grep -H -n -E -i '(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' <files> | grep -v 'Claude-Session: https://claude.ai/code/session_'; grep -H -n -E '(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|-----BEGIN [A-Z ]*KEY-----|://[^/[:space:]:@]+:[^/[:space:]@]+@' <files>; perl -ne 'while (/(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])/g) { my $s=$1; next unless $s=~/[A-Za-z]/ && $s=~/[0-9]/; next if $s=~/^[0-9a-f]{40}$/i; next if $s=~/^[0-9a-f]{64}$/i && /sha256/i; print "$ARGV:$.:\n" } close ARGV if eof' <files>; } | cut -d: -f1,2 | sort -u )"; if [ -n "$H" ]; then echo "PATTERN-HITS (file:line, read each one, then decide):"; echo "$H"; else echo PATTERN-CLEAN; fi
```

What it looks for:
- keyword forms: `password`, `passwd`, `pwd`, `secret`, `token`, `api_key`, `auth`, `bearer`, `cookie`, `session`, followed by `:` or `=` and a value (any case)
- prefixes: `sk-`, `ghp_`, `gho_`, `github_pat_`, `AKIA` plus 16, a JWT (`eyJ...`), `-----BEGIN ... KEY-----`, `://<user>:<pass>@`
- long runs: 32 or more mixed letters and digits with no spaces

For each hit, decide:
- A real credential value (a literal password, token or key): replace it with `[redacted]` in the comment, body or message, add it to the session list, and run both checks again.
- Plainly code reading a variable is fine and stays as it is, for example `password = request.form["password"]` or `token: ${{ secrets.X }}`.
- **Never write `[redacted]` into source code.** A real credential in the diff means the code itself is wrong: stop and ask the owner.
- Unsure and not code: redact.

Allowlist, never redacted:
- 40-hex strings, and any string `git cat-file -e <s>` resolves (git SHAs)
- 24-hex strings next to `_id` or `/goto/` (Qik record ids)
- 64-hex strings next to `sha256`
- the `Claude-Session:` commit trailer when its value is a `https://claude.ai/code/session_` link (the command already skips it)

### The reporter's own issue body

`## Original report` is copied word for word, so it cannot be redacted. If the reporter's original issue body itself contains a credential (a `BLOCKED` or a real pattern hit inside it): stop, post nothing, and tell the owner in chat to edit the issue and rotate the credential. Continue only after the owner says it is done and the check prints `CLEAN`.

### Repo visibility

Before creating an issue from chat text, run
`gh repo view --json visibility -q .visibility`. PUBLIC: show the exact text in
the decision message and wait for yes.

### Leak handling

Leak handling: comment: `gh api -X DELETE repos/<o>/<r>/issues/comments/<id>`.
Issue body: rewrite it, then tell the owner the old text stays in the edit
history until they delete that revision in the GitHub page. Commit not pushed:
amend or rebase before pushing. Pushed: tell the owner, rotate first.

Always also tell the owner to rotate the credential, and say what leaked where.
