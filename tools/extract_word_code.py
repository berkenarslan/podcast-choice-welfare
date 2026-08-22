"""Recover code paragraphs from the original dissertation Word records.

This is a provenance utility, not part of the statistical pipeline. It keeps
the paragraph text and leading whitespace stored in DOCX files. The generated
outputs must be manually reviewed before they are treated as executable code.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from docx import Document


def paragraph_texts(path: Path, start: int, end: int) -> list[str]:
    document = Document(path)
    return [paragraph.text for paragraph in document.paragraphs[start:end]]


def notebook_from_sections(path: Path, sections: list[dict[str, object]]) -> dict:
    cells: list[dict] = []
    for section in sections:
        title = str(section["title"])
        start = int(section["start"])
        end = int(section["end"])
        source = "\n".join(paragraph_texts(path, start, end)).rstrip() + "\n"
        cells.append(
            {
                "cell_type": "markdown",
                "metadata": {},
                "source": [f"## {title}\n"],
            }
        )
        cells.append(
            {
                "cell_type": "code",
                "execution_count": None,
                "metadata": {"provenance": {"docx": path.name, "start": start, "end": end}},
                "outputs": [],
                "source": source.splitlines(keepends=True),
            }
        )
    return {
        "cells": cells,
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3",
            },
            "language_info": {"name": "python", "version": "3"},
        },
        "nbformat": 4,
        "nbformat_minor": 5,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--sections", type=Path)
    parser.add_argument(
        "--text-range",
        nargs=2,
        type=int,
        action="append",
        metavar=("START", "END"),
    )
    args = parser.parse_args()

    if args.text_range:
        blocks = []
        for start, end in args.text_range:
            blocks.append("\n".join(paragraph_texts(args.source, start, end)).rstrip())
        source = "\n\n".join(blocks) + "\n"
        args.output.write_text(source, encoding="utf-8")
        return

    if args.sections is None:
        parser.error("--sections is required unless --text-range is used")
    sections = json.loads(args.sections.read_text(encoding="utf-8"))
    notebook = notebook_from_sections(args.source, sections)
    args.output.write_text(json.dumps(notebook, indent=2, ensure_ascii=False), encoding="utf-8")


if __name__ == "__main__":
    main()
