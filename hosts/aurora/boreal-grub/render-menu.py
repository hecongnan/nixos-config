#!/usr/bin/env python3
"""Render EvoDevo menu images for actual NixOS GRUB entries after each rebuild."""
import argparse
import hashlib
import html
import os
from pathlib import Path
import re
import subprocess
import tempfile

from PIL import ImageFont

ENTRY = re.compile(r'''^(\s*(menuentry|submenu)\s+)("(?:\\.|[^"\\])*"|'[^']*')(.*)$''')
CLASS = re.compile(r'\s+--class boreal_[a-f0-9]{16}\b')


def icon_for(kind, title):
    text = title.lower()
    if kind == 'submenu':
        return 'more'
    if 'windows' in text or 'microsoft' in text:
        return 'Windows'
    if any(word in text for word in ['firmware', 'uefi', 'setup', 'bios']):
        return 'cog'
    if any(word in text for word in ['reboot', 'shutdown', 'power off']):
        return 'power'
    return 'Nix' if 'nix' in text or 'generation' in text else 'unknown'


def atomic_write(path, content):
    fd, temporary = tempfile.mkstemp(prefix='.boreal-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as file:
            file.write(content)
            file.flush()
            os.fsync(file.fileno())
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--theme', type=Path, required=True)
    parser.add_argument('--data', type=Path, required=True)
    parser.add_argument('--font', required=True)
    parser.add_argument('--rsvg', required=True)
    parser.add_argument('--check', required=True)
    args = parser.parse_args()
    original = args.config.read_text()
    font = ImageFont.truetype(args.font, 22)
    icons = args.theme / 'icons'
    icons.mkdir(exist_ok=True)
    output, count = [], 0
    for line in original.splitlines(keepends=True):
        match = ENTRY.match(line.rstrip('\r\n'))
        if not match:
            if re.match(r'^\s*(menuentry|submenu)\s', line):
                raise ValueError('Unsupported GRUB title syntax; retain native text fallback')
            output.append(line)
            continue
        lead, kind, quoted, tail = match.groups()
        title = re.sub(r'\\(["\\$`])', r'\1', quoted[1:-1]) if quoted[0] == '"' else quoted[1:-1]
        tail = CLASS.sub('', tail)
        token = 'boreal_' + hashlib.sha256(f'{count}:{kind}:{title}'.encode()).hexdigest()[:16]
        count += 1
        # Only the image caption is shortened. Real GRUB title/ID/commands stay intact.
        caption = title
        while caption and font.getlength(caption) > 638:
            caption = caption[:-2].rstrip() + '…' if len(caption) > 2 else ''
        glyph = (args.data / icon_for(kind, title)).read_text()
        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="748" height="48">
<path d="{glyph}" transform="translate(48,24) scale(2.016) translate(-12,-12)" fill="#77afc7" fill-rule="evenodd"/>
<text x="96" y="30" font-family="Inter" font-size="22" fill="#98d0eb">{html.escape(caption)}</text>
</svg>'''
        target = icons / (token + '.png')
        subprocess.run([args.rsvg, '-o', str(target), '-'], input=svg.encode(), check=True)
        output.append(f'{lead}{quoted} --class {token}{tail}\n')
    if not count:
        raise ValueError('No literal GRUB entries found')
    result = ''.join(output)
    # Verify before replacing the real configuration; failure leaves it intact.
    fd, name = tempfile.mkstemp(prefix='.boreal-check-', dir=args.config.parent)
    try:
        with os.fdopen(fd, 'w') as file:
            file.write(result)
        subprocess.run([args.check, name], check=True)
    finally:
        os.unlink(name)
    atomic_write(args.config, result)
    print(f'Boreal: rendered {count} actual GRUB entries')


if __name__ == '__main__':
    main()
