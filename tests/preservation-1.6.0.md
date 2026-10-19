# Preservation justifications for 1.6.0

One line per v1.5.0 line that is removed, changed or moved: `- <old place> :: <exact old line> :: <reason>`. `<old place>` is `<file> > <nearest heading>` exactly as `tests/preservation-check.py` prints it. A MOVED line also names its new place in the reason. 1.6.0 adds work order mode for code problems ([superfix-skill#57](https://github.com/thedanielmay/superfix-skill/issues/57), roadmap [superfix-skill#38](https://github.com/thedanielmay/superfix-skill/issues/38)). It is add-only except the in-place edits listed here: the plan names them as journal.md's Status values, the lines check key list, and the widened sandbox `profile()` in criteria.md.

Check: `python3 tests/preservation-check.py "$PWD" --tag v1.5.0` must print `0 unjustified` and exit 0.

## Justifications

## Deviations from the plan (builder, 20 Oct 2026)
