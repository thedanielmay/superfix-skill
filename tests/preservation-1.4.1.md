# Preservation justifications for 1.4.1

One line per v1.4.0 line that is removed, changed or moved: `- <old place> :: <exact old line> :: <reason>`. `<old place>` is `<file> > <nearest heading>` exactly as `tests/preservation-check.py` prints it. A MOVED line also names its new place in the reason. Every change in 1.4.1 is the labels, diagrams, private gap notes and aligned crops release ([superfix-skill#51](https://github.com/thedanielmay/superfix-skill/issues/51)). 1.4.1 is add-only: new lines go next to old ones, so this list should stay empty.

Check: `python3 tests/preservation-check.py "$PWD" --tag v1.4.0` must print `0 unjustified` and exit 0.

## Justifications

## Deviations from the plan (builder, 19 Oct 2026)
