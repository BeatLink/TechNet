"""Pad Nix comment banners so each line is exactly WIDTH columns."""

import argparse
import re
import sys

WIDTH = 150
BANNER = re.compile(r"^(\s*# .*?)([-#]{3,})[ \t]*$")


# True if the line opens or closes an odd number of '' delimiters.
def toggles_string(line):
    return (line.count("''") - line.count("'''")) % 2 == 1


# Rewrites one line to WIDTH, unchanged if it cannot be padded.
def pad(line):
    match = BANNER.match(line)
    if not match:
        return line, False
    head, runout = match.group(1), match.group(2)
    if len(head) >= WIDTH:
        return line, False
    padded = head + runout[0] * (WIDTH - len(head))
    return padded, padded != line


# Pads banners outside strings; returns new text and a change count.
def fix(text):
    out = []
    changed = 0
    in_string = False
    for line in text.split("\n"):
        if in_string:
            out.append(line)
        else:
            line, did = pad(line)
            changed += did
            out.append(line)
        if toggles_string(line):
            in_string = not in_string
    return "\n".join(out), changed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+")
    parser.add_argument(
        "--check", action="store_true", help="report without writing"
    )
    args = parser.parse_args()

    offenders = 0
    for path in args.paths:
        with open(path) as handle:
            text = handle.read()
        fixed, changed = fix(text)
        if not changed:
            continue
        offenders += 1
        if args.check:
            print(f"{path}: {changed} banner(s) not {WIDTH} columns")
        else:
            with open(path, "w") as handle:
                handle.write(fixed)
            print(f"{path}: padded {changed} banner(s)")
    return 1 if (args.check and offenders) else 0


if __name__ == "__main__":
    sys.exit(main())
