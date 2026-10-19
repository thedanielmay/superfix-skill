# Preservation justifications for 1.5.0

One line per v1.4.2 line that is removed, changed or moved: `- <old place> :: <exact old line> :: <reason>`. `<old place>` is `<file> > <nearest heading>` exactly as `tests/preservation-check.py` prints it. A MOVED line also names its new place in the reason. 1.5.0 adds criteria mode for "Everything else" problems ([superfix-skill#54](https://github.com/thedanielmay/superfix-skill/issues/54)); it is add-only except the in-place edits listed here, each named in plan section c9 or c11.

Check: `python3 tests/preservation-check.py "$PWD" --tag v1.4.2` must print `0 unjustified` and exit 0.

## Justifications

## Deviations from the plan (builder, 19 Oct 2026)
