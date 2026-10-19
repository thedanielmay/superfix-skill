# Preservation justifications for 1.4.0

One line per v1.3.1 line that is removed, changed or moved: `- <old place> :: <exact old line> :: <reason>`. `<old place>` is `<file> > <nearest heading>` exactly as `tests/preservation-check.py` prints it. A MOVED line also names its new place in the reason. Every change in 1.4.0 is the pictures and deeper write-up release ([superfix-skill#47](https://github.com/thedanielmay/superfix-skill/issues/47)). 1.4.0 is add-only: new lines go next to old ones, so this list should stay short.

Check: `python3 tests/preservation-check.py "$PWD" --tag v1.3.1` must print `0 unjustified` and exit 0.

## Justifications

