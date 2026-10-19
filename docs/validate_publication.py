"""Check publication consistency only; this does not execute SQL."""
from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'docs/query-manifest.json').read_text())
assert len(manifest) == 90
assert len(list((root / 'til/ko').glob('day*.md'))) == 17
assert len(list((root / 'til/en').glob('day*.md'))) == 17
for day in range(1, 18):
    doc = (root / f'til/en/day{day:02}.md').read_text()
    exercises = re.split(r'(?=^## Exercise \d+)', doc, flags=re.M)[1:]
    records = [r for r in manifest if r['day'] == day]
    assert len(exercises) == len(records)
    sql_file = (root / f'sql/day{day:02}.sql').read_text()
    for section, record in zip(exercises, records):
        final = re.search(r'### (?:Final query recorded in the journal|Last recorded query[^\n]*)\n\n```sql\n(.*?)\n```', section, re.S)
        assert final, (day, record['exercise'])
        query = final.group(1)
        assert hashlib.sha256(query.encode()).hexdigest() == record['query_sha256']
        assert query in sql_file
    assert doc.count('```') % 2 == 0
for file in root.rglob('*.md'):
    text = file.read_text()
    assert text.count('```') % 2 == 0, file
    for link in re.findall(r'\]\(([^)]+)\)', text):
        if not re.match(r'https?://|#|mailto:', link):
            target = link.split('#')[0]
            assert (file.parent / target).exists(), (file, link)
for language in ['ko', 'en']:
    assert not re.search(r'\bC\d{4,}\b', (root / f'til/{language}/day06.md').read_text())
assert 'ERROR 1064' in (root / 'til/en/day11.md').read_text()
assert not (root / 'notion-export.json').exists()
print('PASS: 17 bilingual sessions, 90 queries, hashes, links, fences, pseudonyms and historical error/follow-up history.')

for day in range(12,18):
    for lang in ('ko','en'):
        text=(root/f'til/{lang}/day{day:02}.md').read_text()
        assert '/Users/' not in text
        if day in (12,13): assert not re.search(r'\bC\d{5,}\b',text)
    sql_text=(root/f'sql/day{day:02}.sql').read_text()
    ko=(root/f'til/ko/day{day:02}.md').read_text()
    for q in re.findall(r'```sql\n(.*?)\n```',(root/f'til/en/day{day:02}.md').read_text(),re.S):
        if q in sql_text: assert q in ko
print('PASS: new Korean/English final SQL alignment, no local paths or original finance IDs.')
