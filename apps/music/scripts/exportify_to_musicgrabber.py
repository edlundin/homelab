#!/usr/bin/env python3
"""Convert an Exportify Spotify CSV to MusicGrabber bulk-import lines."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_file", type=Path)
    parser.add_argument("--output", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    output = args.output or args.csv_file.with_suffix(".musicgrabber.txt")

    with args.csv_file.open(newline="", encoding="utf-8-sig") as source:
        reader = csv.DictReader(source)
        required = {"Artist Name(s)", "Track Name"}
        missing = required.difference(reader.fieldnames or [])
        if missing:
            names = ", ".join(sorted(missing))
            raise SystemExit(f"missing Exportify column(s): {names}")

        lines: list[str] = []
        seen: set[tuple[str, str]] = set()
        for row in reader:
            artist = row["Artist Name(s)"].strip()
            title = row["Track Name"].strip()
            key = (artist.casefold(), title.casefold())
            if not artist or not title or key in seen:
                continue
            seen.add(key)
            lines.append(f"{artist} - {title}")

    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {len(lines)} tracks to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
