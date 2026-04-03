#!/usr/bin/env python3
"""
HTML Writer for TubeScribe
==========================

Generates clean HTML documents from markdown transcript data.
Zero dependencies, opens in any browser, looks great.

Usage:
    from html_writer import create_html_from_markdown
    create_html_from_markdown(md_path, output_path)
"""

import re
from datetime import datetime


def markdown_to_html(md_text: str) -> str:
    """Convert markdown text to HTML."""
    lines = md_text.split('\n')
    html_lines = []
    in_table = False
    table_past_separator = False  # Track if we've passed the header separator
    in_blockquote = False
    blockquote_lines = []
    in_code_block = False
    code_block_lines = []
    list_stack = []  # Stack of ('ul'|'ol') for nested list tracking

    def flush_blockquote():
        """Flush accumulated blockquote lines."""
        nonlocal in_blockquote, blockquote_lines
        if blockquote_lines:
            content = '</p><p>'.join(blockquote_lines)
            html_lines.append(f'<blockquote><p>{content}</p></blockquote>')
            blockquote_lines = []
        in_blockquote = False

    def flush_list():
        """Close all open list tags."""
        nonlocal list_stack
        while list_stack:
            html_lines.append(f'</{list_stack.pop()}>')

    def close_blocks():
        """Close any open table or list."""
        nonlocal in_table, table_past_separator
        if in_table:
            html_lines.append('</table>')
            in_table = False
            table_past_separator = False
        flush_list()

    for line in lines:
        # Fenced code block handling
        if line.strip().startswith('```'):
            if in_code_block:
                html_lines.append(f'<pre><code>{escape_html(chr(10).join(code_block_lines))}</code></pre>')
                code_block_lines = []
                in_code_block = False
            else:
                close_blocks()
                if in_blockquote:
                    flush_blockquote()
                in_code_block = True
            continue
        if in_code_block:
            code_block_lines.append(line)
            continue

        # Blockquote handling: > text
        if line.startswith('> '):
            close_blocks()
            quote_text = process_inline_formatting(line[2:])
            blockquote_lines.append(quote_text)
            in_blockquote = True
            continue
        elif in_blockquote:
            flush_blockquote()

        # List handling: - item or * item (unordered), 1. item (ordered)
        ul_match = re.match(r'^(\s*)[-*]\s+(.+)', line)
        ol_match = re.match(r'^(\s*)\d+\.\s+(.+)', line)
        if ul_match or ol_match:
            if in_table:
                html_lines.append('</table>')
                in_table = False
                table_past_separator = False
            if ul_match:
                list_type = 'ul'
                item_text = ul_match.group(2)
            else:
                list_type = 'ol'
                item_text = ol_match.group(2)
            if not list_stack:
                html_lines.append(f'<{list_type}>')
                list_stack.append(list_type)
            html_lines.append(f'<li>{process_inline_formatting(item_text)}</li>')
            continue

        # If we were in a list and this line isn't a list item, close the list
        if list_stack:
            flush_list()

        # Headers
        if line.startswith('# '):
            close_blocks()
            html_lines.append(f'<h1>{process_inline_formatting(line[2:])}</h1>')
        elif line.startswith('## '):
            close_blocks()
            html_lines.append(f'<h2>{process_inline_formatting(line[3:])}</h2>')
        elif line.startswith('### '):
            close_blocks()
            html_lines.append(f'<h3>{process_inline_formatting(line[4:])}</h3>')
        elif line.startswith('---'):
            close_blocks()
            html_lines.append('<hr>')
        elif line.startswith('|'):
            # Table handling
            if not in_table:
                html_lines.append('<table>')
                in_table = True
                table_past_separator = False
            # Check for separator row (contains only |, -, :, and spaces)
            if re.match(r'^[\s|:\-]+$', line):
                table_past_separator = True
                continue  # Skip separator row
            cells = [c.strip() for c in line.split('|')[1:-1]]
            # First row before separator = <th>, all rows after = <td>
            tag = 'td' if table_past_separator else 'th'
            row = ''.join(f'<{tag}>{process_inline_formatting(c)}</{tag}>' for c in cells)
            html_lines.append(f'<tr>{row}</tr>')
        elif line.strip() == '':
            close_blocks()
            html_lines.append('')
        elif line.lstrip().startswith('<') and not line.lstrip().startswith('<http'):
            # Raw HTML line - pass through safe tags only, escape everything else
            close_blocks()
            stripped = line.lstrip()
            # Allowlist of safe HTML tags (reject unknown tags entirely)
            safe_tags = {'div', 'span', 'br', 'p', 'ul', 'ol', 'li', 'pre', 'code',
                         'sub', 'sup', 'details', 'summary', 'dl', 'dt', 'dd',
                         'abbr', 'cite', 'small', 'mark', 'ins', 'del',
                         'figcaption', 'figure'}
            tag_match = re.match(r'<\s*/?\s*(\w+)', stripped)
            if tag_match and tag_match.group(1).lower() in safe_tags:
                # Strip event handler attributes (on*="...") and style attributes
                safe_line = re.sub(r'\s+on\w+\s*=\s*["\'][^"\']*["\']', '', line, flags=re.IGNORECASE)
                safe_line = re.sub(r'\s+on\w+\s*=\s*\S+', '', safe_line, flags=re.IGNORECASE)
                safe_line = re.sub(r'\s+style\s*=\s*["\'][^"\']*["\']', '', safe_line, flags=re.IGNORECASE)
                safe_line = re.sub(r'\s+style\s*=\s*\S+', '', safe_line, flags=re.IGNORECASE)
                html_lines.append(safe_line)
            else:
                html_lines.append(f'<p>{escape_html(line)}</p>')
        else:
            close_blocks()
            # Process inline formatting
            processed = process_inline_formatting(line)
            html_lines.append(f'<p>{processed}</p>')

    # Flush any remaining open blocks
    if in_code_block:
        html_lines.append(f'<pre><code>{escape_html(chr(10).join(code_block_lines))}</code></pre>')
    if in_blockquote:
        flush_blockquote()
    close_blocks()

    return '\n'.join(html_lines)


def escape_html(text: str) -> str:
    """Escape HTML special characters."""
    return (text
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace("'", '&#39;'))


def process_inline_formatting(text: str) -> str:
    """Process inline markdown formatting with XSS protection."""
    # Extract inline code BEFORE escaping (content should be escaped but not formatted)
    code_placeholders = {}
    code_counter = 0

    def extract_code(match):
        nonlocal code_counter
        code_text = match.group(1)
        placeholder = f"\x00CODE{code_counter}\x00"
        code_counter += 1
        code_placeholders[placeholder] = code_text
        return placeholder

    text = re.sub(r'`([^`]+)`', extract_code, text)

    # Extract links BEFORE escaping so URLs don't get double-encoded
    link_placeholders = {}
    link_counter = 0

    def extract_link(match):
        nonlocal link_counter
        link_text, url = match.groups()
        placeholder = f"\x00LINK{link_counter}\x00"
        link_counter += 1
        link_placeholders[placeholder] = (link_text, url)
        return placeholder

    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', extract_link, text)

    # Escape HTML to prevent XSS
    text = escape_html(text)

    # Bold: **text** or __text__
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    text = re.sub(r'__(.+?)__', r'<strong>\1</strong>', text)

    # Italic: *text* or _text_
    text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
    text = re.sub(r'(?<!\w)_(.+?)_(?!\w)', r'<em>\1</em>', text)

    # Restore links with safe URL validation
    for placeholder, (link_text, url) in link_placeholders.items():
        safe_text = escape_html(link_text)
        if url.startswith(('http://', 'https://')) or (url.startswith('/') and not url.startswith('//')):  # block protocol-relative URLs
            safe_url = url.replace('&', '&amp;').replace('"', '&quot;')
            link_html = f'<a href="{safe_url}" target="_blank">{safe_text}</a>'
        else:
            link_html = f'{safe_text} ({escape_html(url)})'
        text = text.replace(placeholder, link_html)

    # Restore inline code
    for placeholder, code_text in code_placeholders.items():
        text = text.replace(placeholder, f'<code>{escape_html(code_text)}</code>')

    return text


def create_html_from_markdown(md_path: str, output_path: str) -> str:
    """Convert a markdown file to a styled HTML document."""
    with open(md_path, 'r', encoding='utf-8') as f:
        md_content = f.read()
    
    # Extract title from first H1
    title_match = re.search(r'^# (.+)$', md_content, re.MULTILINE)
    title = title_match.group(1) if title_match else "TubeScribe Transcript"
    
    # Convert content
    html_body = markdown_to_html(md_content)
    
    # Wrap in full HTML document with nice styling
    html_doc = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{escape_html(title)}</title>
    <style>
        :root {{
            --bg: #ffffff;
            --text: #1a1a1a;
            --accent: #0066cc;
            --border: #e0e0e0;
            --quote-bg: #f5f5f5;
        }}
        @media (prefers-color-scheme: dark) {{
            :root {{
                --bg: #1a1a1a;
                --text: #e0e0e0;
                --accent: #66b3ff;
                --border: #333;
                --quote-bg: #252525;
            }}
        }}
        * {{ box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            background: var(--bg);
            color: var(--text);
        }}
        h1 {{ 
            font-size: 2rem; 
            border-bottom: 2px solid var(--accent);
            padding-bottom: 0.5rem;
        }}
        h2 {{ 
            font-size: 1.5rem; 
            margin-top: 2rem;
            color: var(--accent);
        }}
        h3 {{ font-size: 1.25rem; }}
        a {{ color: var(--accent); }}
        a:hover {{ text-decoration: none; }}
        hr {{ 
            border: none; 
            border-top: 1px solid var(--border); 
            margin: 2rem 0;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
        }}
        th, td {{
            padding: 0.5rem 1rem;
            text-align: left;
            border: 1px solid var(--border);
        }}
        th {{ background: var(--quote-bg); }}
        p {{ margin: 0.75rem 0; }}
        strong {{ font-weight: 600; }}
        ul, ol {{ margin: 0.75rem 0; padding-left: 2rem; }}
        li {{ margin: 0.25rem 0; }}
        pre {{
            background: var(--quote-bg);
            padding: 1rem;
            border-radius: 6px;
            overflow-x: auto;
            margin: 1rem 0;
        }}
        pre code {{ background: none; padding: 0; }}
        code {{
            font-family: 'SF Mono', Menlo, Consolas, monospace;
            background: var(--quote-bg);
            padding: 0.15rem 0.4rem;
            border-radius: 3px;
            font-size: 0.9em;
        }}
        .timestamp {{
            font-family: monospace;
            background: var(--quote-bg);
            padding: 0.1rem 0.3rem;
            border-radius: 3px;
        }}
        footer {{
            margin-top: 3rem;
            padding-top: 1rem;
            border-top: 1px solid var(--border);
            font-size: 0.85rem;
            color: #888;
        }}
    </style>
</head>
<body>
{html_body}
<footer>
    Generated by TubeScribe 🎬 • {datetime.now().strftime('%Y-%m-%d %H:%M')}
</footer>
</body>
</html>'''
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html_doc)
    
    return output_path


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        md_path = sys.argv[1]
        out_path = sys.argv[2] if len(sys.argv) > 2 else md_path.replace('.md', '.html')
        result = create_html_from_markdown(md_path, out_path)
        print(f"Created: {result}")
