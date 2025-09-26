#!/usr/bin/env python3
from pathlib import Path

# Regenerate `index.html` from current `.zip` files
out = Path('index.html')
zip_files = sorted(p.name for p in Path('.').glob('*.zip'))

lines = [
    '<!DOCTYPE html>',
    '<html lang="en">',
    '<head><meta charset="utf-8"><title>Repositories</title></head>',
    '<body>'
]

for name in zip_files:
    lines.append(f'<a href="{name}">{name}</a><br>')

# Updated Fen link
lines.append('<a href="https://fenlightanonymouse.github.io/packages/">FenlightAM</a><br>')
lines.append('</body>')
lines.append('</html>')

out.write_text('\n'.join(lines), encoding='utf-8')
print(f'Wrote {out} with {len(zip_files)} zip links.')