"""Rebuild the app catalogue from the 44 original, unmodified PDF uploads.

Curated topic definitions live in curriculum.py. The catalogue deduplicates by
SHA256, preserves provenance, and never treats blank PDFs as usable papers.
"""
import hashlib
import json
import re
import shutil
from pathlib import Path
from pypdf import PdfReader
from curriculum import topics
from extra_practice import EXTRA_PRACTICE
from topic_extensions import EXTENSIONS

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets'
(ASSETS / 'papers').mkdir(parents=True, exist_ok=True)

# id: subject, year, exam, resource type, matching memo id, qualification
spec = {
 1: ('maths',2024,'November Paper 1','paper',16,''),
 2: ('maths',2021,'July Paper 1','paper',3,''),
 3: ('maths',2021,'July Paper 1','memo',None,'Handwritten marking guidelines'),
 4: ('maths',None,'Blank upload 4','unavailable',None,'All pages are blank; no title or year can be verified'),
 5: ('maths',2021,'July Paper 2','paper',None,''),
 6: ('maths',2021,'November Paper 1','paper',8,''),
 7: ('maths',None,'Blank upload 7','unavailable',None,'All pages are blank; no title or year can be verified'),
 8: ('maths',2021,'November Paper 1','memo',None,'Scanned handwritten marking guidelines'),
 9: ('maths',2021,'November Paper 2','paper',10,''),
 10: ('maths',2021,'November Paper 2','memo',None,'Handwritten marking guidelines'),
 11: ('maths',2023,'November Paper 1','paper',None,''),
 13: ('maths',2023,'November Paper 2','paper',14,''),
 14: ('maths',2023,'November Paper 2','memo',None,'Scanned handwritten marking guidelines'),
 16: ('maths',2024,'November Paper 1','memo',None,'Partial scanned memo; pages are not in exam order. Use printed question numbers.'),
 17: ('maths',2024,'November Paper 2','paper',18,''),
 18: ('maths',2024,'November Paper 2','memo',None,'Post-marking guidelines; annotations retained'),
 19: ('life',2020,'November Paper 1','paper',None,''),
 20: ('life',None,'November Practical','paper',None,'The document does not state a year'),
 21: ('life',2020,'November Paper 2','paper',None,'References a separate source booklet that was not supplied'),
 22: ('life',2022,'November Theory Section B','paper',24,''),
 23: ('life',2022,'November Section A Answer Booklet','supplement',None,'Contains Section A questions; this is not a marking memo'),
 24: ('life',2022,'November Theory Section B','memo',None,'Year inferred from matching questions in the 2022 paper; no year on memo cover'),
 25: ('life',2023,'November Practical','paper',None,'Scanned practical examination'),
 26: ('life',2023,'November Paper 2','paper',28,''),
 28: ('life',2023,'November Paper 2 Essay','memo',None,'Year inferred from matching the climate-change essay in the 2023 paper'),
 29: ('life',2024,'November Paper 1','paper',30,''),
 30: ('life',2024,'November Paper 1','memo',None,'Some source memo explanations are imprecise. Revision notes use standard scientific explanations.'),
 31: ('physical',2021,'November Paper 1 Physics','paper',32,''),
 32: ('physical',2021,'November Paper 1 Physics','memo',None,''),
 33: ('physical',2021,'November Paper 2 Chemistry','paper',34,''),
 34: ('physical',2021,'November Paper 2 Chemistry','memo',None,''),
 35: ('physical',2024,'November Paper 1 Physics','paper',36,''),
 36: ('physical',2024,'November Paper 1 Physics','memo',None,''),
 37: ('physical',2024,'November Paper 2 Chemistry','paper',None,'A 2024 Chemistry memo was not supplied. Upload 38 duplicates the Physics memo.'),
 39: ('ap',2023,'November Further Studies Mathematics','paper',40,''),
 40: ('ap',2023,'November Further Studies Mathematics','memo',None,'Scanned handwritten marking guidelines'),
 41: ('ap',2024,'November Probability Statistics and Algebra','paper',42,''),
 42: ('ap',2024,'November Probability Statistics and Algebra','memo',None,'Scanned handwritten marking guidelines'),
 43: ('sports',2024,'November Sport and Exercise Science','paper',44,''),
 44: ('sports',2024,'November Sport and Exercise Science','memo',None,'Question numbering and pagination differ from the paper; match by question text'),
}
duplicates = {12:11,15:1,27:26,38:36}
subjects = [
 dict(id='maths',name='Maths',subtitle='Find your formula for success',color='6654D9',light='EEEAFE',icon='calculate'),
 dict(id='ap',name='AP Maths',subtitle='A little further. A little brighter.',color='CB702E',light='FFF0DB',icon='functions'),
 dict(id='physical',name='Physical Science',subtitle='Big ideas. Real-world discoveries.',color='287FA5',light='E5F4FE',icon='science'),
 dict(id='life',name='Life Science',subtitle='Explore the extraordinary in life',color='30836A',light='E5F5EC',icon='eco'),
 dict(id='sports',name='Sports Science',subtitle='The science behind your best',color='C65378',light='FDE9EF',icon='sports'),
]
papers=[]
for n,(subject,year,exam,kind,memo,note) in spec.items():
 slug=re.sub('[^a-z0-9]+','-',f'{subject}-{year or "year-unknown"}-{exam}-{kind}'.lower()).strip('-')+'.pdf'
 original=ROOT/f'{n}.pdf'
 published=ASSETS/'papers'/slug
 source=original if original.is_file() else published
 if not source.is_file():
  raise FileNotFoundError(f'Missing source PDF: {original.name} or assets/papers/{slug}')
 reader=PdfReader(source)
 if source.resolve()!=published.resolve():
  shutil.copyfile(source, published)
 papers.append(dict(id=str(n),subject=subject,year=year,title=f'{exam} · {year or "Year not stated"}',kind=kind,memo=str(memo) if memo else None,note=note,file=slug,pages=len(reader.pages),sha256=hashlib.sha256(source.read_bytes()).hexdigest(),originals=[f'{n}.pdf']+[f'{d}.pdf' for d,target in duplicates.items() if target==n]))

by_id={p['id']:p for p in papers}
assert set(EXTRA_PRACTICE)=={t['title'] for t in topics}, 'Extra-practice topics must match the curriculum'
assert set(EXTENSIONS)=={t['title'] for t in topics}, 'Every topic needs a challenge and card extension'
for i,t in enumerate(topics):
 additions=EXTRA_PRACTICE[t['title']]
 assert len(additions)>=4, f'Expected at least four extra exercises for {t["title"]}'
 t['practice'].extend(dict(question=q,answer=a) for q,a in additions)
 t['id']=t['subject']+'-'+re.sub('[^a-z0-9]+','-',t['title'].lower()).strip('-')
 t['minutes']=8+len(t['notes'])*2
 extension=EXTENSIONS[t['title']]
 t['challenges']=extension['challenges']
 assert len(t['challenges'])>=2 and len(extension['cards'])>=4
 # Keep the previous nine card indices intact before appending new material.
 t['cards']=[dict(front=h,back=b) for h,b in t['notes']]+[dict(front=q['question'],back=q['answer']) for q in t['practice']]+[dict(front=q['question'],back=q['answer']) for q in t['challenges']]+extension['cards']
 t['notes']=[dict(heading=h,body=b) for h,b in t['notes']]
 for ref in t['sources']:
  p=by_id[ref['paper']]
  assert 1 <= ref['page'] <= p['pages'], (t['title'],ref)
  ref['memo']=p['memo']
  if ref.get('memoPage') and p['memo']:
   assert ref['memoPage']<=by_id[p['memo']]['pages']

content=dict(subjects=subjects,papers=papers,topics=topics,sourceCount=44,duplicates=duplicates,contentVersion=3)
(ASSETS/'content.json').write_text(json.dumps(content,ensure_ascii=False,indent=2),encoding='utf-8')
audit=ROOT/'docs'/'SOURCE_AUDIT.md'; audit.parent.mkdir(exist_ok=True)
lines=['# Source audit','','All 44 uploaded PDFs were opened. Original bytes are preserved in assets/papers; duplicates share one published copy. Blank uploads are retained in the catalogue as unavailable. Page links use PDF page positions, not printed page labels.','','| Upload(s) | Subject | Resource | Type | Pages | Notes |','|---|---|---|---|---|---|']
for p in papers:
 lines.append('| '+', '.join(p['originals'])+' | '+p['subject']+' | '+p['title']+' | '+p['kind']+' | '+str(p['pages'])+' | '+p['note']+' |')
lines += ['','## Learning content','','Topics are editorial groupings based on the supplied papers, not a claim of complete curriculum coverage. Original topic questions link to complete source pages so equations, diagrams, tables and reading passages remain intact. Matching original memos are linked when supplied; missing memos are stated explicitly. New practice, worked answers, revision notes and flashcards are generated study material, not official marking guidelines.','',f'{len(topics)} topics; {sum(len(t["practice"]) for t in topics)} regular worked questions; {sum(len(t["challenges"]) for t in topics)} stretch challenges; {sum(len(t["cards"]) for t in topics)} flashcards.','','The Life Science 2022 memo has an anaphase/metaphase inconsistency; notes explain normal anaphase correctly. Some supplied Life Science and Sports Science memo statements oversimplify absorption, energy systems and nutrition; generated notes use conventional school-level explanations instead of reproducing those errors.']
audit.write_text('\n'.join(lines),encoding='utf-8')
print(f'Built {len(papers)} unique resources, {len(topics)} topics')
