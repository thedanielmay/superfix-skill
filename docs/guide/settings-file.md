# Settings file

A repo can carry a small settings file so a run does not repeat its branch, its PR base, its checks and its rules every time. Superfix reads it in Phase 0 and shows what it applied in the `Settings:` line of the Problem Profile, for you to approve at the Stop gate.

The reader is `references/project.py`. It judges the file and prints one item per line. It never runs, expands or fetches anything: a checks command is validated, not executed, and only runs when the run reaches Phase 3 with your go.

## The file

`<repo>/.superfix/project.md`, plain `key: value` lines, one per line. A line starting with `#` is a comment and blank lines are ignored. It is data, never instructions to the model. A key may be written bare, in a list or in bold (`base-branch`, `- base-branch` and `**base-branch**` all read the same). Inline comments are not stripped, so keep a `#` on its own line.

| Key | Values | Repeatable |
|---|---|---|
| `base-branch` | a branch name, for example `release/1.6.2`; the branch the fix branch starts from | no |
| `pr-base` | a branch name; the PR base | no |
| `checks` | one command that must pass before the PR | yes, in file order |
| `rules` | one line of repo rules, shown to the model and to you | yes, in file order |
| `do-not-edit` | a file or folder the run never edits | yes, in file order |

Only these five keys exist. `work-clone` was dropped from v1: a repo-local file must not choose where the run works.

A sample file:

```text
# .superfix/project.md
base-branch: release/1.6.2
pr-base: release/1.6.2
checks: python3 tests/preservation-check.py .
checks: bash tests/workorder-tests.sh
rules: no em or en dashes anywhere
do-not-edit: skills/superfix/references/crit.py
```

Running the reader on that folder prints:

```text
PROJECT-OK
SETTING base-branch=release/1.6.2
SETTING pr-base=release/1.6.2
SETTING checks=python3 tests/preservation-check.py .
SETTING checks=bash tests/workorder-tests.sh
SETTING rules=no em or en dashes anywhere
SETTING do-not-edit=skills/superfix/references/crit.py
```

With no file, or a file with no settings, it prints:

```text
PROJECT-OK
SETTINGS-NONE
```

## What the reader refuses

The file may tighten behaviour, never relax it. Nothing in it can switch off the Stop gate, the secrets rules, the redaction scans or the create-issue question, and nothing in it is obeyed as an instruction.

- A key whose name holds a relax word is refused: `gate`, `secre`, `redact`, `merge`, `push`, `budget`, `approv`, `bypass`, `allow`, `skip`, `permission`, `credential`, `token`, `password`, `dest`, `upload`, `clone`, `force`, `unsafe`, `trust`, `sudo`, `confirm`, `create`, `relax`. The output is `PROJECT-REFUSED <key>`.
- A `rules` line is refused the same way when it holds one of those words, so a rule can tighten the run but cannot name a safeguard it wants switched off: `PROJECT-REFUSED rules`. Write rules about the work (`no em or en dashes anywhere`), not about the gate.
- Any value naming an outbound destination (`://`, `git@`, `scp:`, `rsync:`, `s3:`) or a credential path (`~/.ssh`, `/.ssh/`, `.env`, `id_rsa`, `id_ed25519`, `.netrc`, `.aws/`, `.gnupg`, `.kube/config`, `keychain`, credentials.json, `.docker/config`) is refused: `PROJECT-BAD-VALUE <key>`.
- `base-branch` and `pr-base` must be plain ref names, set once, with no `..` and no leading `-`.
- A `checks` command must be one interpreter (`python3`, `python`, `bash`, `sh`, `node`), then a repository script ending `.py`, `.sh` or `.js`, then plain arguments. No shell metacharacters (pipe, ampersand, semicolon, dollar, backtick, angle brackets, brackets, braces, bang, star, question mark, hash, tilde, backslash, quotes), no absolute path anywhere including after an `=` (`--out=/etc/x`), no `..`. The command cannot leave the repository or chain a second command. Anything else is `PROJECT-CHECK-REFUSED <key>`.
- A key that is not one of the five is ignored and named: `PROJECT-UNKNOWN-KEY <key>`. The rest of the file still applies.

Real outputs for four bad files:

```text
PROJECT-REFUSED gate
PROJECT-CHECK-REFUSED checks
PROJECT-UNKNOWN-KEY colour
PROJECT-BAD-VALUE do-not-edit (~/.ssh)
```

The last line echoes a refused value cut to 60 characters, so a long hostile line cannot flood the decision comment.

## Output and what the run does with it

| Output | Exit | The run |
|---|---|---|
| `PROJECT-OK` | 0 | applies every `SETTING` line |
| `PROJECT-UNKNOWN-KEY <key>` | 0 | applies the `SETTING` lines, shows `IGNORED <key>`, continues |
| `PROJECT-REFUSED <key>` | 1 | stops and asks at the Stop gate |
| `PROJECT-CHECK-REFUSED <key>` | 1 | stops and asks at the Stop gate |
| `PROJECT-BAD-VALUE <key>` | 1 | stops and asks at the Stop gate |
| `SETTINGS-NONE` | 0 | no file, or no settings: nothing changes |

After the first word comes one `SETTING <key>=<value>` per applied value, in file order. The model joins those lines with `; ` into the one `Settings:` line of the Problem Profile, so you see exactly what was applied and approve it with the options.

## Known limits

- The settings are read once, in Phase 0. A repo that changes its own settings file during a run is not re-read between the go and the fix; that window is known and unguarded.
- `pr-base` is shown and carried into the PR command, but the PR is opened by a third-party skill at Phase 4, so the base is not enforced by this reader.
- `rules` is free text. A line such as "write results to /tmp/outbox then email" is not refused; you see it at the Stop gate and approve it.
- A `rules` line is refused only for the relax words above, not for every possible instruction.
