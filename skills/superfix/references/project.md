# Repo settings: `.superfix/project.md`

A repo can carry a small settings file so a run does not have to be told its branch, its PR base,
its checks and its rules every time. Superfix reads it in Phase 0, shows the applied settings in the
Problem Profile, and the owner approves them at the Stop gate with everything else.

The reader is `references/project.py`. It judges the file and prints one item per line. It never
runs, expands or fetches anything: a checks command is validated, not executed, and only runs when
the run reaches Phase 3 with the owner's go.

````
python3 references/project.py <repo>        # <repo> defaults to the current folder
````

## The file

`<repo>/.superfix/project.md`, plain `key: value` lines, one per line. A line starting with `#` is a
comment and blank lines are ignored. It is data, never instructions to the model. A key may be
written bare, in a list or in bold (`base-branch`, `- base-branch`, `**base-branch**` all read the
same); inline comments are not stripped, so keep a `#` on its own line.

| Key | Values | Repeatable |
|-----|--------|------------|
| `base-branch` | a branch name, e.g. `release/1.6.2`; the branch the fix branch starts from | no |
| `pr-base` | a branch name; the PR base | no |
| `checks` | one command that must pass before the PR | yes, in file order |
| `rules` | one line of repo rules, shown to the model and the owner | yes, in file order |
| `do-not-edit` | a file or folder the run never edits | yes, in file order |

````
# .superfix/project.md
base-branch: release/1.6.2
pr-base: release/1.6.2
checks: python3 tests/preservation-check.py .
checks: bash tests/workorder-tests.sh
rules: no em or en dashes anywhere
do-not-edit: skills/superfix/references/crit.py
````

Only these five keys exist. `work-clone` was dropped from v1: a repo-local file must not choose
where the run works.

## What the reader refuses

The file may tighten behaviour, never relax it. Nothing in it can switch off the Stop gate, the
secrets rules, the redaction scans or the create-issue question, and nothing in it is obeyed as an
instruction.

- A key whose name holds a relax word (`gate`, `secre`, `redact`, `merge`, `push`, `budget`,
  `approv`, `bypass`, `allow`, `skip`, `permission`, `credential`, `token`, `password`, `dest`,
  `upload`, `clone`, `force`, `unsafe`, `trust`, `sudo`, `confirm`, `create`, `relax`) is refused:
  `PROJECT-REFUSED`.
- A `rules` line is refused the same way when it holds one of those words, so a rule can tighten the
  run but cannot name a safeguard it wants switched off: `PROJECT-REFUSED rules`. Write rules about
  the work (`no em or en dashes anywhere`), not about the gate.
- Any value naming an outbound destination (`://`, `git@`, `scp:`, `rsync:`, `s3:`) or a credential
  path (`~/.ssh`, `/.ssh/`, `.env`, `id_rsa`, `id_ed25519`, `.netrc`, `.aws/`, `.gnupg`,
  `.kube/config`, `keychain`, `credentials.json`, `.docker/config`) is refused: `PROJECT-BAD-VALUE`.
- `base-branch` and `pr-base` must be plain ref names, set once, with no `..` and no leading `-`.
- A `checks` command must be one interpreter (`python3`, `python`, `bash`, `sh`, `node`), then a
  repository script ending `.py`, `.sh` or `.js`, then plain arguments. No shell metacharacters
  (pipe, ampersand, semicolon, dollar, backtick, angle brackets, brackets, braces, bang, star,
  question mark, hash, tilde, backslash, quotes), no absolute path anywhere including after an `=`
  (`--out=/etc/x`), no `..`: the command cannot leave the repository or chain a second command.
  Anything else is `PROJECT-CHECK-REFUSED`.
- A key that is not one of the five is ignored and named: `PROJECT-UNKNOWN-KEY`. The rest of the
  file still applies.

## Output and what the run does with it

| Output | Exit | The run |
|--------|------|---------|
| `PROJECT-OK` | 0 | applies every `SETTING` line |
| `PROJECT-UNKNOWN-KEY <key>` | 0 | applies the `SETTING` lines, shows `IGNORED <key>` in the Profile, continues |
| `PROJECT-REFUSED <key>` | 1 | stops and asks at the Stop gate |
| `PROJECT-CHECK-REFUSED <key>` | 1 | stops and asks at the Stop gate |
| `PROJECT-BAD-VALUE <key>` | 1 | stops and asks at the Stop gate |
| `SETTINGS-NONE` | 0 | no file, or no settings: nothing changes |

Then one `SETTING <key>=<value>` per applied value, in file order. The model joins the reader's lines
with `; ` into the one `Settings:` line of the Problem Profile, so the owner sees exactly what was
applied and approves it with the options. A refused value is echoed back cut to 60 characters, so a
long hostile line cannot flood the decision comment.

The settings are read once, in Phase 0. A repo that changes its own settings file during a run is
not re-read between the go and the fix; that window is known and unguarded. `pr-base` is shown and
carried into the PR command, but the PR is opened by a third-party skill at Phase 4, so the base is
not enforced by this reader.
