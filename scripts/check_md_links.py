#!/usr/bin/env python3
"""Fail if any relative Markdown link points to a file that does not exist."""
import pathlib
import re
import sys

LINK = re.compile(r"\]\(([^)#\s]+)(?:#[^)]*)?\)")
EXTERNAL = ("http://", "https://", "mailto:")


def broken_links(path: pathlib.Path) -> list[str]:
    return [
        target
        for target in LINK.findall(path.read_text(encoding="utf-8"))
        if not target.startswith(EXTERNAL) and not (path.parent / target).exists()
    ]


def main(files: list[str]) -> int:
    failed = False
    for name in files:
        for target in broken_links(pathlib.Path(name)):
            print(f"{name}: broken link -> {target}")
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
