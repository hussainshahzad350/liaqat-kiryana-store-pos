"""Capture an existing SQLite database through a read-only source connection."""
import argparse
import datetime
import hashlib
import json
from pathlib import Path
import sqlite3

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('source', type=Path)
parser.add_argument('output_directory', type=Path)
args = parser.parse_args()
source_path = args.source.resolve(strict=True)
args.output_directory.mkdir(parents=True, exist_ok=True)
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d_%H%M%S_%f')
copy_path = args.output_directory.resolve() / f'existing_store_{stamp}.db'
with sqlite3.connect(source_path.as_uri() + '?mode=ro', uri=True) as source:
    with sqlite3.connect(copy_path) as target:
        source.backup(target)
        version = target.execute('PRAGMA user_version').fetchone()[0]
        integrity = target.execute('PRAGMA integrity_check').fetchall()
        tables = [row[0] for row in target.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")]
        counts = {name: target.execute('SELECT COUNT(*) FROM "' + name.replace('"', '""') + '"').fetchone()[0] for name in tables}
manifest = {
    'source': str(source_path), 'copy': str(copy_path),
    'source_open_mode': 'read-only', 'version': version,
    'integrity': integrity, 'counts': counts,
    'sha256': hashlib.sha256(copy_path.read_bytes()).hexdigest(),
    'provenance': 'Existing default workspace database; real-store provenance unconfirmed',
}
copy_path.with_suffix('.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
print(json.dumps(manifest, indent=2))
