# Preservation justifications for 1.6.1

One line per v1.6.0 line that is removed, changed or moved: `- <old place> :: <exact old line> :: <reason>`. `<old place>` is `<file> > <nearest heading>` exactly as `tests/preservation-check.py` prints it. A MOVED line also names its new place in the reason. 1.6.1 adds the `criteria` work-order kind ([superfix-skill#59](https://github.com/thedanielmay/superfix-skill/issues/59), roadmap [superfix-skill#38](https://github.com/thedanielmay/superfix-skill/issues/38)). It is add-only except the in-place edits listed here: the plan names them as the SKILL.md Work order mode section lines, criteria.md section 22, and the `WO_KINDS` plus `cmd_wo_*` commands in the `crit.py` block.

Check: `python3 tests/preservation-check.py "$PWD" --tag v1.6.0` must print `0 unjustified` and exit 0.

## Justifications

(none yet: T1 changes no existing skills/superfix/ line, only the plugin version and this file)
