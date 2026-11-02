"""Validate published sources and all topic references without changing them."""
import hashlib
import json
import re
from pathlib import Path
from pypdf import PdfReader

root=Path(__file__).resolve().parents[1]
data=json.loads((root/'assets/content.json').read_text(encoding='utf-8'))
papers={p['id']:p for p in data['papers']}
originals=[]
for p in papers.values():
 published=root/'assets/papers'/p['file']
 assert hashlib.sha256(published.read_bytes()).hexdigest()==p['sha256'],p['file']
 for f in p['originals']:
  originals.append(f)
  if (root/f).exists():
   assert hashlib.sha256((root/f).read_bytes()).hexdigest()==p['sha256'],f
 if p['memo']:
  memo=papers[p['memo']]
  assert memo['subject']==p['subject'] and memo['year']==p['year'] and memo['kind']=='memo'
 if p['kind']=='unavailable':
  reader=PdfReader(published)
  assert all(not page.get_contents() or not page.get_contents().get_data().strip() for page in reader.pages)
assert set(originals)=={f'{n}.pdf' for n in range(1,45)}
assert len(originals)==44
ids=set()
for t in data['topics']:
 assert t['id'] not in ids
 ids.add(t['id'])
 assert len(t['practice'])>=2 and len(t['notes'])>=3 and len(t['cards'])>=5
 assert t['formula'] and t['tip'] and t['sources']
 for r in t['sources']:
  p=papers[r['paper']]
  assert p['kind'] in ['paper','supplement'] and p['subject']==t['subject']
  assert 1<=r['page']<=p['pages']
  if r['memo'] and r['memoPage']:
   assert 1<=r['memoPage']<=papers[r['memo']]['pages']
for s in data['subjects']:
 assert any(t['subject']==s['id'] for t in data['topics'])
 assert any(p['subject']==s['id'] and p['kind']=='paper' for p in papers.values())
print('PASS: 44 originals accounted for; checksums, blank uploads, memo pairs, source pages and all topic packs validated.')
print(len(data['topics']),'topics;',sum(len(t['practice']) for t in data['topics']),'worked questions;',sum(len(t['cards']) for t in data['topics']),'flashcards.')

if '--review' in __import__('sys').argv:
 for t in data['topics']:
  print('\nTOPIC:',t['title'])
  for r in t['sources']:
   f=root/'tmp/extracted'/f'{r["paper"]}.txt'
   if not f.exists():continue
   pages=dict(re.findall(r'PAGE (\d+)\n(.*?)(?=\n\nPAGE |\Z)',f.read_text(encoding='utf-8'),re.S))
   lines=[x.strip() for x in pages.get(str(r['page']),'').splitlines() if len(x.strip())>25 and not any(k in x for k in ['___','Page ','PAGE ','DLSHCCH'])]
   print('  ',r['paper'],r['page'],r['label'],' :: ',' | '.join(lines[:6]))
