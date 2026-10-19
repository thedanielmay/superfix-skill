# Preservation justifications for 1.6.0

One line per v1.5.0 line that is removed, changed or moved: `- <old place> :: <exact old line> :: <reason>`. `<old place>` is `<file> > <nearest heading>` exactly as `tests/preservation-check.py` prints it. A MOVED line also names its new place in the reason. 1.6.0 adds work order mode for code problems ([superfix-skill#57](https://github.com/thedanielmay/superfix-skill/issues/57), roadmap [superfix-skill#38](https://github.com/thedanielmay/superfix-skill/issues/38)). It is add-only except the in-place edits listed here: the plan names them as journal.md's Status values, the lines check key list, and the widened sandbox `profile()` in criteria.md.

Check: `python3 tests/preservation-check.py "$PWD" --tag v1.5.0` must print `0 unjustified` and exit 0.

## Justifications

- skills/superfix/references/criteria.md > The script :: def profile(tmp, reads): :: plan (b) Where things live, Sandbox: 1.6.0 reuses the same profile() function with two added parameters, the programs allowed to start and whole read folders; the line now reads `def profile(tmp, reads, execs=(), read_dirs=()):`. With both empty the profile string is byte for byte the 1.5.0 one (the 427 criteria-mode command tests still pass).
- skills/superfix/references/criteria.md > The script :: temporary folder, system paths and the Python install, metadata only on those paths' parents.""" :: the same docstring, continued with the 1.6.0 parameters (bash, the tools check.sh calls and node may start; the worktree and node's install are read; with execs also process-fork, the execs' own files and sysctl-read, which node needs: probed). Same place.
- skills/superfix/references/criteria.md > The script :: "/opt/homebrew", "/dev", "/private/var/select", real(sys.base_prefix), real(sys.prefix), fw] :: the same system read list, now with `+ [real(d) for d in read_dirs]` added at the end of the line, so the worktree and node's install can be read. Same place.
- skills/superfix/references/criteria.md > The script :: f"(allow process-exec (literal {q(py)}) (subpath {q(fw)}))" :: the same Python exec rule, now followed on the same line by one `(literal ...)` per allowed program (`execs`), so bash and node can start inside the work order sandbox. Same place; with no execs the rule is unchanged.
- skills/superfix/references/criteria.md > The script :: "(allow file-read-metadata " + " ".join(f"(literal {q(x)})" for x in anc) + ")" :: the same metadata rule, now preceded on its line by `+ ("(allow process-fork)(allow sysctl-read)" if execs else "")`, which is empty for every 1.5.0 caller. Same place.

## Deviations from the plan (builder, 20 Oct 2026)
