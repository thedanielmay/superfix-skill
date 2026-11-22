# Journal for a run with no issue

New in 1.7.7 ([superfix-skill#144](https://github.com/thedanielmay/superfix-skill/issues/144) step C). SKILL.md (Input Handling) says when to read this file: in full, on a run with no issue, before the first journal entry. A run on an issue never reads it. The two sections moved here word for word from `journal.md`; "above" in them means `journal.md` (Decision message, the body template), which the run has already read.

### Create-issue question (description only, in a git repo with a GitHub remote)

The LAST numbered question of the decision message, always, so the owner's numbered reply stays predictable:

```
<N>. No issue exists yet. Create one in <owner/repo> (<private|PUBLIC>) with this
   record? (yes / no, keep it in a local file)
```

- This question has no recommended answer. "Keep executing" and other "yes to all" replies do not create an issue: unless the owner says yes to this question itself, the answer is no (keep the journal file, create nothing), on public and private repos alike.

- Get the visibility first: `gh repo view --json visibility -q .visibility`.
- If the repo is PUBLIC, the question adds: "It is public, so anyone can read it. The text it would post is below." and shows the redacted Original report.
- If the duplicate search (`gh issue list --state open --search "<3 key words>" --limit 5`) found a likely match, name it in the question and offer to use it instead.
- Yes: write the title to `~/.superfix/runs/<run-key>/title.txt` (under `umask 077`) and the body to a file, run both checks on both, then `gh issue create --title "$(cat ~/.superfix/runs/<run-key>/title.txt)" --body-file <body file>`. Next, BEFORE writing the issue line into the journal, move the run folder to the issue key (both keys written out, lowercase); it refuses if the target exists and then rewrites the `key` file. On `RUN-MOVED`, add a line under the journal file's Status line pointing to the issue, and continue on the issue. On `REFUSED-EXISTS`: keep the journal key, never overwrite the other folder, write the issue line as `Issue: <link> (run key: <journal run-key>)`, and tell the owner another run already holds that issue's folder. No: keep going in the journal file.

```bash
umask 077; S="$HOME/.superfix/runs/<journal run-key>"; T="$HOME/.superfix/runs/<owner>+<repo>+<N>"; if [ -e "$T" ]; then echo "REFUSED-EXISTS $T"; else mv "$S" "$T" && printf '%s\n' '<owner>+<repo>+<N>' > "$T/key" && echo RUN-MOVED; fi
```

### File-mode journal (no issue)

- Path: `~/.superfix/journal/<owner>-<repo>/<YYYY-MM-DD>-<slug>.md`, or `~/.superfix/journal/<folder-name>/<YYYY-MM-DD>-<slug>.md` when there is no remote. `mkdir -p` the folder first, then create the run folder with the journal key (redaction.md, Run folder).
- It is never inside the repo, so it is never committed and never breaks the `git status --porcelain` check.
- Same body template as above. The Status line is the file's first line, updated in place.
- `## Original report` holds the owner's description copied exactly, including URLs, record ids and commit ids. Only a credential is replaced by `[redacted]` (redaction check first). Never summarise or reword it.
- Comments become dated `### <YYYY-MM-DD HH:MM> <stage>` entries appended at the end, each starting with the plain-English callout.
- No issue: the label commands do not run; the `Labels:` line reads `Labels: none (no issue)`. The `Diagram:` and `Gap note:` lines are written as for an issue.
- The decision entry carries the same required `Pictures:` line as the decision comment (Decision message, above).
- Say the file path in chat every time you stop.
