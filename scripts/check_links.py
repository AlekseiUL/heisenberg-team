#!/usr/bin/env python3
"""Check local file links in root, docs and examples Markdown; fail closed.

Checks inline links/images and reference definitions, not heading anchors or
remote URLs. Fenced/inline code is documentation, not a live link.
"""
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

INLINE = re.compile(r'!?\[[^\]\n]*\]\(\s*(<[^>\n]+>|[^\s)]+)(?:\s+["\'][^\n]*?["\'])?\s*\)')
REFERENCE = re.compile(r'^\s{0,3}\[[^\]\n]+\]:\s*(<[^>\n]+>|\S+)', re.M)


def prose(text):
    lines = []
    fence = None
    for line in text.splitlines():
        marker = re.match(r'^\s{0,3}(`{3,}|~{3,})', line)
        if marker:
            token = marker.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
            continue
        if fence is None:
            lines.append(re.sub(r'(`+).*?\1', '', line))
    return '\n'.join(lines)


def check(root):
    documents = set(root.glob('*.md'))
    for folder in ('docs', 'examples'):
        documents.update((root / folder).rglob('*.md'))
    if not documents:
        print('No Markdown documents found')
        return 1
    failures = []
    for document in sorted(documents):
        text = prose(document.read_text(encoding='utf-8'))
        for raw in INLINE.findall(text) + REFERENCE.findall(text):
            url = urlsplit(raw.strip('<>'))
            if url.scheme or url.netloc or not url.path:
                continue
            path = unquote(url.path)
            target = root / path.lstrip('/') if path.startswith('/') else document.parent / path
            if not target.exists():
                failures.append(f'{document.relative_to(root)}: {raw}')
    for failure in failures:
        print('Broken link: ' + failure)
    print(f'Checked {len(documents)} documents; {len(failures)} broken local links')
    return 1 if failures else 0


if __name__ == '__main__':
    raise SystemExit(check(Path(sys.argv[1] if len(sys.argv) > 1 else '.').resolve()))
