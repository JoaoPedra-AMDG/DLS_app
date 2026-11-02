"""Stamp the installable web release and its offline app-shell asset list."""
import hashlib
import json
import os
from pathlib import Path

root=Path(__file__).resolve().parents[1]
build=root/'build'/'web'
assert (build/'main.dart.js').is_file(), 'Run flutter build web first'
revision=os.environ.get('GITHUB_SHA') or hashlib.sha256((build/'main.dart.js').read_bytes()+(build/'assets/assets/content.json').read_bytes()).hexdigest()
files=[]
for p in sorted(build.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(build).as_posix()
 if rel.startswith('assets/assets/papers/') or rel in ['sw.js','flutter_service_worker.js'] or rel.endswith('.map'):continue
 files.append('./'+rel)
worker=(root/'web/sw.js').read_text(encoding='utf-8').replace('__BUILD_ID__',revision[:16]).replace('/*__PRECACHE__*/ []',json.dumps(files))
(build/'sw.js').write_text(worker,encoding='utf-8')
(build/'release.json').write_text(json.dumps({'app':'For Rosa','revision':revision}),encoding='utf-8')
print('Prepared For Rosa installable release:',revision[:12],';',len(files),'app-shell files; PDFs cache only on demand.')
