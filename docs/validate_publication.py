"""Validate bilingual publication consistency; execution evidence is audit-results.json."""
from pathlib import Path
import hashlib,html,json,re
root=Path(__file__).resolve().parents[1]
DAYS=28;QUERIES=153
manifest=json.loads((root/'docs/query-manifest.json').read_text())
audit=json.loads((root/'docs/audit-results.json').read_text())
assert len(manifest)==QUERIES
assert audit['queries_checked']==audit['passed']==QUERIES and audit['failed']==0
assert len(audit['checks'])==QUERIES
assert len({(r['day'],r['exercise']) for r in manifest})==QUERIES
for lang in ['ko','en']:assert len(list((root/f'til/{lang}').glob('day*.md')))==DAYS
norm=lambda q:re.sub(r'\s+','',q).lower()
def cell(s):
 s=re.sub(r'<[^>]*>','',s)
 return html.unescape(s).replace('\\_','_').replace('`','').replace('**','').strip()
def tables(s):
 result=[]
 for block in re.findall(r'^\|[^\n]*\n\|[^\n]*\n(?:\|[^\n]*\n?)+',s,re.M):
  lines=block.strip().splitlines();heads=tuple(cell(x) for x in lines[0].strip('|').split('|'))
  rows=[tuple(cell(x) for x in line.strip('|').split('|')) for line in lines[2:]]
  result.append((heads,rows))
 return result
warnings=[]
for day in range(1,DAYS+1):
 ko=(root/f'til/ko/day{day:02}.md').read_text();en=(root/f'til/en/day{day:02}.md').read_text();sql=(root/f'sql/day{day:02}.sql').read_text()
 parts=re.split(r'(?=^## Exercise \d+)',en,flags=re.M)[1:];records=[r for r in manifest if r['day']==day]
 assert len(parts)==len(records),(day,'exercise count')
 kt=tables(ko)
 for part,rec in zip(parts,records):
  m=re.search(r'### Final query recorded in the journal\n\n```sql\n(.*?)\n```',part,re.S);assert m,(day,'missing final')
  q=m[1];sha=hashlib.sha256(q.encode()).hexdigest()
  assert sha==rec['query_sha256'],(day,rec['exercise'],'manifest hash')
  assert q in sql,(day,rec['exercise'],'query file')
  assert norm(q) in norm(ko),(day,rec['exercise'],'Korean final SQL')
  a=next(x for x in audit['checks'] if x['day']==day and x['exercise_index']==parts.index(part)+1)
  assert a['ok'] and a['query_sha256']==sha,(day,'audit hash')
  # The English edition may show a subset, so require each recorded row in the corresponding Korean table.
  areas=re.findall(r'### (?:Recorded output[^\n]*|Follow-up verification[^\n]*)\n\n(.*?)(?=\n### |\n## |\Z)',part,re.S)
  for area in areas:
   for heads,rows in tables(area):
    candidates=[rs for hs,rs in kt if hs==heads]
    for row in rows:
     assert any(row in rs for rs in candidates),(day,rec['exercise'],'recorded bilingual row',row)
 for lang,text in [('ko',ko),('en',en)]:
  assert text.count('```')%2==0,(day,lang,'fences')
  assert '/Users/' not in text and '/tmp/' not in text,(day,lang,'private path')
  if day in [6,12,13,18,19,25,27,28]:assert not re.search(r'\bC\d{5,}\b',text),(day,'original finance ID')
  assert not re.search(r'COUNT\(\*\*\)|COUNT\(\\\*\*\)|\*FROM\*',text),(day,'broken code')
for lang in ['ko','en']:
 readme=(root/('README.ko.md' if lang=='ko' else 'README.md')).read_text()
 for day in range(1,DAYS+1):
  for p in [f'til/ko/day{day:02}.md',f'til/en/day{day:02}.md',f'sql/day{day:02}.sql']:assert p in readme
for f in root.rglob('*.md'):
 s=f.read_text();assert s.count('```')%2==0,f
 for link in re.findall(r'\]\(([^)]+)\)',s):
  if not re.match(r'https?://|#|mailto:',link):assert (f.parent/link.split('#')[0]).exists(),(f,link)
assert 'ERROR 1064' in (root/'til/en/day11.md').read_text()
assert '-- UNRESOLVED:' not in (root/'sql/day11.sql').read_text()
assert '| 2012/2013 | 1.552 |' not in (root/'til/en/day01.md').read_text()
assert not (root/'notion-export.json').exists()
assert (root/'docs/audit.ko.md').exists() and (root/'docs/audit.en.md').exists()
print('PASS: 28 bilingual sessions, 153 exact final query hashes, recorded output-row alignment, all index links, balanced fences, scoped execution evidence and privacy checks.')
