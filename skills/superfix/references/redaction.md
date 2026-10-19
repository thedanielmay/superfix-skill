# Redaction

New in 1.3.0. SKILL.md ("Decision and redaction") says when to run this check: before ANY push, issue create, comment, body edit, PR create or `--body-file`. A match blocks the post until it is redacted.

### Session list

Session list: every exact string the owner gave as a credential, plus any found
in tool output. Keep it in a file made with `umask 077; mktemp` outside the
repo; delete it at the end of the run.

```bash
SECRETS="$(umask 077; mktemp)"       # once per run; one secret per line, no blank lines
printf '%s\n' '<exact string>' >> "$SECRETS"
T="$(umask 077; mktemp -d)"          # scratch for the files being checked
```

A blank line in `$SECRETS` matches everything, so never write one.

### Exact-string check (catches a password with no keyword)

```bash
git diff origin/<base>...HEAD > "$T/diff"; git log --format=%B origin/<base>..HEAD > "$T/msgs"
[ -s "$SECRETS" ] && grep -F -n -f "$SECRETS" "$T/diff" "$T/msgs" <each body file> && echo BLOCKED
```

The `[ -s ]` guard matters: macOS grep with an empty pattern file matches every line, so an empty session list would block every post.

Before a branch exists (issue create, comment, body edit), run the same `grep` over the body files only.

### Pattern check (report each hit, then decide)

- keyword forms only: (password|passwd|pwd|secret|token|api[_-]?key|auth|
  bearer|cookie|session)\s*[:=]\s*\S+   (any case)
- prefixes: sk-, ghp_, gho_, github_pat_, AKIA[0-9A-Z]{16}, eyJ<...>.<...>.,
  -----BEGIN <...> KEY-----, ://<user>:<pass>@
- long runs: 32 or more mixed letters and digits with no spaces

```bash
grep -n -E -i '(password|passwd|pwd|secret|token|api[_-]?key|auth|bearer|cookie|session)[[:space:]]*[:=][[:space:]]*[^[:space:]]+' <files>
grep -n -E '(^|[^A-Za-z0-9])(sk-[A-Za-z0-9]|ghp_|gho_|github_pat_)|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.|-----BEGIN [A-Z ]*KEY-----|://[^/[:space:]:@]+:[^/[:space:]@]+@' <files>
perl -ne 'while (/(?<![A-Za-z0-9])([A-Za-z0-9]{32,})(?![A-Za-z0-9])/g) { my $s=$1; next unless $s=~/[A-Za-z]/ && $s=~/[0-9]/; next if $s=~/^[0-9a-f]{40}$/i; next if $s=~/^[0-9a-f]{64}$/i && /sha256/i; print "$ARGV:$.: long run: $s\n" } close ARGV if eof' <files>
```

`<files>` is the same list as the exact-string check: `"$T/diff" "$T/msgs"` and each body file, written out (zsh does not split a variable into several file names).

Allowlist, never redacted:
- 40-hex strings, and any string `git cat-file -e <s>` resolves (git SHAs)
- 24-hex strings next to `_id` or `/goto/` (Qik record ids)
- 64-hex strings next to `sha256`
- the `Claude-Session:` commit trailer when its value is a `https://claude.ai/code/session_` link
Not allowlisted and unsure: redact. Replace with [redacted].

### Repo visibility

Repo visibility: before creating an issue from chat text, run
`gh repo view --json visibility -q .visibility`. PUBLIC: show the exact text in
the decision message and wait for yes.

### Leak handling

Leak handling: comment: `gh api -X DELETE repos/<o>/<r>/issues/comments/<id>`.
Issue body: rewrite it, then tell the owner the old text stays in the edit
history until they delete that revision in the GitHub page. Commit not pushed:
amend or rebase before pushing. Pushed: tell the owner, rotate first.

Always also tell the owner to rotate the credential, and say what leaked where.
At the end of the run: `rm -f "$SECRETS"; rm -rf "$T"`.
