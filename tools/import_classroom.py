"""Import only catalogued Classroom downloads; keep a reproducible source audit.

Run locally after browser downloads. CI uses the checked-in source manifest.
Office originals remain unchanged; LibreOffice creates PDF viewing copies.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from collections import defaultdict
from pathlib import Path
from urllib.parse import urlparse
from pypdf import PdfReader
from classroom_sources import resource_kind, display_title

ROOT = Path(__file__).resolve().parents[1]

def slug(value):
    return re.sub(r'[^a-z0-9]+', '-', value.lower()).strip('-')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--downloads', type=Path, default=Path.home()/'Downloads')
    parser.add_argument('--soffice', type=Path)
    args = parser.parse_args()
    posts = json.loads((ROOT/'tmp/classroom-catalog.json').read_text(encoding='utf-8'))
    log = json.loads((ROOT/'tmp/classroom-download-log.json').read_text(encoding='utf-8'))
    links = {}
    for post in posts:
        for link in post['links']:
            match = re.search(r'/d/([^/]+)', link['url'])
            if not match:
                continue
            key = match[1]
            name = re.sub(r'^Attachment: [^:]+: ', '', link['name']).strip()
            entry = links.setdefault(key, dict(id=key, name=name, subjects=[], sections=[]))
            if post['subject'] not in entry['subjects']:
                entry['subjects'].append(post['subject'])
            if post['section'] not in entry['sections']:
                entry['sections'].append(post['section'])
    by_name = defaultdict(list)
    for source in links.values():
        by_name[source['name']].append(source)
    originals = ROOT/'assets/classroom'
    originals.mkdir(exist_ok=True)
    private = ROOT/'tmp/classroom-originals'
    private.mkdir(exist_ok=True)
    extracted = ROOT/'tmp/classroom-extracted'
    extracted.mkdir(exist_ok=True)
    resources, missing = [], []
    hashes = {}
    for name, sources in by_name.items():
        safe_name = re.sub(r'[<>:"/\\|?*]', '_', name).strip().rstrip('.')
        base = Path(safe_name)
        candidates = [p for p in args.downloads.iterdir() if p.is_file() and (
            p.name == safe_name or re.fullmatch(re.escape(base.stem)+r' \(\d+\)'+re.escape(base.suffix), p.name)
        )]
        candidates.sort(key=lambda p: p.stat().st_mtime)
        for index, source in enumerate(sources):
            local = private/(source['id']+base.suffix.lower())
            if not local.exists():
                if index >= len(candidates):
                    missing.append(source)
                    continue
                shutil.copyfile(candidates[index], local)
            digest = hashlib.sha256(local.read_bytes()).hexdigest()
            if digest in hashes:
                resource = hashes[digest]
                resource['sourceIds'].append(source['id'])
                resource['sections'] = sorted(set(resource['sections']+source['sections']))
                resource['subjects'] = sorted(set(resource['subjects']+source['subjects']))
                continue
            # Student-owned assignment copies must be reviewed separately before
            # inclusion. Teacher handouts do not contain a learner's full name.
            if re.search(r'Rosa\s+Pedra|Edited - Saint|Re project', name, re.I):
                missing.append(dict(**source, reason='Personal assignment copy: local review required'))
                continue
            suffix = base.suffix.lower()
            if suffix not in ['.pdf', '.docx', '.doc', '.pptx', '.ppt']:
                missing.append(dict(**source, reason='Unsupported format'))
                continue
            published_name = source['subjects'][0]+'-'+slug(base.stem)[:110]+'-'+digest[:8]+suffix
            target = originals/published_name
            if not target.exists():
                shutil.copyfile(local, target)
            pdf_name = Path(published_name).with_suffix('.pdf').name
            pdf_path = ROOT/'assets/papers'/pdf_name
            if suffix == '.pdf':
                if not pdf_path.exists():
                    shutil.copyfile(local, pdf_path)
            elif (private/(source['id']+'.pdf')).exists() and not pdf_path.exists():
                shutil.copyfile(private/(source['id']+'.pdf'), pdf_path)
            elif args.soffice and not pdf_path.exists():
                subprocess.run([str(args.soffice), '-env:UserInstallation='+ (ROOT/'tmp/libreoffice-profile').as_uri(),
                    '--headless','--convert-to','pdf','--outdir',str(pdf_path.parent),str(target)], check=True, timeout=180)
            if not pdf_path.exists():
                missing.append(dict(**source, reason='PDF conversion pending'))
                continue
            reader = PdfReader(pdf_path)
            text_path = extracted/(pdf_path.stem+'.txt')
            if not text_path.exists():
                text = '\n\n'.join(f'PAGE {i+1}\n{p.extract_text() or ""}' for i,p in enumerate(reader.pages))
                text_path.write_text(text, encoding='utf-8')
            years = re.findall(r'\b(20\d{2})\b', base.stem)
            first_page=text_path.read_text(encoding='utf-8')[:700]
            kind=resource_kind(name,source['sections'],first_page)
            resource = dict(id='cc-'+digest[:16],subject=source['subjects'][0],subjects=source['subjects'],
                title=display_title(name,source['sections']),year=int(years[-1]) if years else None,kind=kind,availability='local',
                file=pdf_name,originalFile=published_name,originalName=name,format=suffix[1:].upper(),
                pages=len(reader.pages),sha256=digest,pdfSha256=hashlib.sha256(pdf_path.read_bytes()).hexdigest(),
                sourceIds=[source['id']],sections=source['sections'],imported='2026-11-03')
            resources.append(resource)
            hashes[digest]=resource
    (ROOT/'assets/classroom_manifest.json').write_text(json.dumps(resources,ensure_ascii=False,indent=2),encoding='utf-8')
    (ROOT/'tmp/classroom-missing.json').write_text(json.dumps(missing,ensure_ascii=False,indent=2),encoding='utf-8')
    print(f'{len(resources)} unique documents imported; {len(missing)} pending source copies/conversions.')
    for s in sorted(set(x for r in resources for x in r['subjects'])):
        print(s, sum(s in r['subjects'] for r in resources))

if __name__ == '__main__':
    main()
