#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

python3 - <<'PY'
import json
import struct
import zlib
from pathlib import Path

source = Path('branding/mark.json')
mark = json.loads(source.read_text())
glyph = mark['glyph']
background = bytes.fromhex(mark['background'][1:]) + b'\xff'
foreground = bytes.fromhex(mark['foreground'][1:]) + b'\xff'
transparent = b'\x00' * 4


def png(size, mode='icon'):
    rows = []
    for y in range(size):
        row = bytearray(b'\x00')
        for x in range(size):
            # Adaptive foregrounds must fit Android's central 66/108 safe zone.
            px = (x + .5) * 108 / size
            py = (y + .5) * 108 / size
            gx, gy = int((px - 29) / 10), int((py - 19) / 10)
            ink = (29 <= px < 79 and 19 <= py < 89
                   and glyph[gy][gx] == '1')
            if mode == 'adaptive':
                gx, gy = int((px - 36.5) / 7), int((py - 29.5) / 7)
                ink = (36.5 <= px < 71.5 and 29.5 <= py < 78.5
                       and glyph[gy][gx] == '1')
            row.extend(foreground if ink else
                       (background if mode == 'icon' else transparent))
        rows.append(row)

    def chunk(kind, data):
        return (struct.pack('>I', len(data)) + kind + data
                + struct.pack('>I', zlib.crc32(kind + data)))

    # Binary assets carry their SPDX identifier in PNG metadata (also inside ICO).
    return (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', struct.pack('>2I5B', size, size, 8, 6, 0, 0, 0))
            + chunk(b'tEXt', b'License\x00SPDX-License-Identifier: AGPL-3.0-only')
            + chunk(b'IDAT', zlib.compress(b''.join(rows), 9))
            + chunk(b'IEND', b''))


def write(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def ico():
    sizes = (16, 24, 32, 48, 64, 128, 256)
    entries, images = [], []
    offset = 6 + 16 * len(sizes)
    for size in sizes:
        data = png(size)
        entries.append(struct.pack('<4B2H2I', size % 256, size % 256,
                                   0, 0, 1, 32, len(data), offset))
        images.append(data)
        offset += len(data)
    return struct.pack('<3H', 0, 1, len(sizes)) + b''.join(entries + images)


for name in ('res/icon.ico', 'res/tray-icon.ico',
             'flutter/windows/runner/resources/app_icon.ico',
             'res/msi/Package/Resources/icon.ico'):
    write(name, ico())
for name in ('res/icon.png', 'flutter/assets/icon.png'):
    write(name, png(512))

rects = ''.join(f'<rect x="{29 + x * 10}" y="{19 + y * 10}" width="10" height="10"/>'
                for y, row in enumerate(glyph) for x, cell in enumerate(row) if cell == '1')
svg = ('<!-- SPDX-License-Identifier: AGPL-3.0-only -->\n'
       '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">'
       f'<rect width="108" height="108" rx="18" fill="{mark["background"]}"/>'
       f'<g fill="{mark["foreground"]}">{rects}</g></svg>\n')
for name in ('res/logo.svg', 'flutter/assets/icon.svg', 'res/logo-header.svg'):
    write(name, svg.encode())

android = Path('flutter/android/app/src/main/res')
path_data = ' '.join(f'M{29 + x * 10},{19 + y * 10}h10v10h-10z'
                     for y, row in enumerate(glyph) for x, cell in enumerate(row) if cell == '1')
write(android / 'drawable/floating_window.xml',
      ('<!-- SPDX-License-Identifier: AGPL-3.0-only -->\n'
       '<vector xmlns:android="http://schemas.android.com/apk/res/android" '
       'android:width="320dp" android:height="320dp" android:viewportWidth="108" android:viewportHeight="108">'
       f'<path android:fillColor="{mark["background"]}" android:pathData="M0,0h108v108H0z"/>'
       f'<path android:fillColor="{mark["foreground"]}" android:pathData="{path_data}"/></vector>\n').encode())
for density, scale in (('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2),
                       ('xxhdpi', 3), ('xxxhdpi', 4)):
    folder = android / f'mipmap-{density}'
    for name in ('ic_launcher.png', 'ic_launcher_round.png'):
        write(folder / name, png(int(48 * scale)))
    write(folder / 'ic_launcher_foreground.png', png(int(108 * scale), 'adaptive'))
    write(folder / 'ic_stat_logo.png', png(int(24 * scale), 'notification'))
write(android / 'values/ic_launcher_background.xml',
      ('<?xml version="1.0" encoding="utf-8"?>\n'
       '<!-- SPDX-License-Identifier: AGPL-3.0-only -->\n'
       f'<resources><color name="ic_launcher_background">{mark["background"]}</color></resources>\n').encode())
print(f'Generated everywhere Windows, Flutter and Android icons from {source}')
PY
