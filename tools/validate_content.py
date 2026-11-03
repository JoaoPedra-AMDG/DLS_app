"""Validate published sources and all topic references without changing them."""
import hashlib
import json
import re
from pathlib import Path
from pypdf import PdfReader

root=Path(__file__).resolve().parents[1]
data=json.loads((root/'assets/content.json').read_text(encoding='utf-8'))
papers={p['id']:p for p in data['papers']}
documents={d['id']:d for d in data.get('classroom',[])}
for d in documents.values():
 if d.get('availability')=='school':
  from urllib.parse import urlparse
  for link in [d['sourceUrl']]+[link['url'] for link in d['sourceLinks']]:
   u=urlparse(link)
   assert u.scheme=='https' and u.hostname in ['drive.google.com','docs.google.com']
   assert not u.query and not u.fragment
  assert d['sourceIds'] and not d.get('file')
  continue
 original=root/'assets/classroom'/d['originalFile']
 pdf=root/'assets/papers'/d['file']
 assert hashlib.sha256(original.read_bytes()).hexdigest()==d['sha256'],d['title']
 assert hashlib.sha256(pdf.read_bytes()).hexdigest()==d['pdfSha256'],d['title']
 assert d['pages']>0 and d['sourceIds'] and d['subject'] in d['subjects']
source_index=root/'assets/classroom_source_index.json'
if source_index.exists():
 indexed={s['id'] for s in json.loads(source_index.read_text(encoding='utf-8'))}
 represented=[sid for d in documents.values() for sid in d['sourceIds']]
 assert set(represented)==indexed, 'Every catalogued teaching source must have a copy or school link'
 assert len(represented)==len(set(represented)), 'Teaching sources must not appear in multiple resources'
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
 assert isinstance(t.get('group'),str) and t['group'].strip(), f'Missing topic group: {t["title"]}'
 assert t['id'] not in ids
 ids.add(t['id'])
 assert len(t['practice'])>=6 and len(t['notes'])>=3 and len(t['cards'])>=15 and len(t['challenges'])>=2
 questions=[q['question'].strip().casefold() for q in t['practice']+t['challenges']]
 assert len(questions)==len(set(questions)), f'Duplicate practice question: {t["title"]}'
 assert all(q['question'].strip() and q['answer'].strip() for q in t['practice']+t['challenges'])
 assert all(c['front'].strip() and c['back'].strip() for c in t['cards'])
 assert t['formula'] and t['tip'] and (t['sources'] or t.get('classroomSources'))
 for document_id in t.get('classroomSources',[]):
  assert document_id in documents and t['subject'] in documents[document_id]['subjects']
 for r in t['sources']:
  p=papers[r['paper']]
  assert p['kind'] in ['paper','supplement'] and p['subject']==t['subject']
  assert 1<=r['page']<=p['pages']
  if r['memo'] and r['memoPage']:
   assert 1<=r['memoPage']<=papers[r['memo']]['pages']
for s in data['subjects']:
 assert any(t['subject']==s['id'] for t in data['topics'])
 assert any(p['subject']==s['id'] and p['kind']=='paper' for p in papers.values()) or any(s['id'] in d['subjects'] for d in documents.values())
print('PASS: 44 originals accounted for; checksums, blank uploads, memo pairs, source pages and all topic packs validated.')
print(len(data['topics']),'topics;',sum(len(t['practice']) for t in data['topics']),'regular worked questions;',sum(len(t['challenges']) for t in data['topics']),'challenges;',sum(len(t['cards']) for t in data['topics']),'flashcards.')
print(sum(d.get('availability')!='school' for d in documents.values()),'local Classroom documents; original and viewing-copy checksums validated.')

if '--review' in __import__('sys').argv:
 for t in data['topics']:
  print('\nTOPIC:',t['title'])
  for r in t['sources']:
   f=root/'tmp/extracted'/f'{r["paper"]}.txt'
   if not f.exists():continue
   pages=dict(re.findall(r'PAGE (\d+)\n(.*?)(?=\n\nPAGE |\Z)',f.read_text(encoding='utf-8'),re.S))
   lines=[x.strip() for x in pages.get(str(r['page']),'').splitlines() if len(x.strip())>25 and not any(k in x for k in ['___','Page ','PAGE ','DLSHCCH'])]
   print('  ',r['paper'],r['page'],r['label'],' :: ',' | '.join(lines[:6]))
