"""Metadata for local teaching files and authenticated school links."""
import hashlib
import re
from pathlib import PurePosixPath

def resource_kind(name, sections, first_page=''):
    text=(name+' '+' '.join(sections)).lower()
    for pattern,kind in [(r'memo|answers|solutions','memo'),(r'rubric','rubric'),(r'scope','scope'),(r'week.*plan','plan')]:
        if re.search(pattern,text): return kind
    if name.lower().endswith(('.ppt','.pptx')): return 'slides'
    if re.search(r'exam|cycle test|quiz|past paper',text):
        return 'scope' if 'scope' in first_page[:600].lower() else 'paper'
    if re.search(r'worksheet|questions|activity',text): return 'worksheet'
    return 'notes'

def display_title(name, sections):
    title=PurePosixPath(name).stem
    if re.fullmatch(r'[0-9A-Fa-f]{15,}',title) and sections:
        return sections[0].strip()
    return title

def school_links(index, downloaded):
    have={sid for d in downloaded for sid in d['sourceIds']}
    groups={}
    for source in index:
        if source['id'] in have: continue
        key=(tuple(sorted(source['subjects'])),source['name'])
        if key not in groups:
            stable=hashlib.sha256(('|'.join(key[0])+'|'+key[1]).encode()).hexdigest()[:16]
            groups[key]=dict(id='school-'+stable,subject=source['subjects'][0],subjects=source['subjects'],
                title=display_title(source['name'],source['sections']),
                kind=resource_kind(source['name'],source['sections']),
                format=PurePosixPath(source['name']).suffix.lstrip('.').upper() or 'DOCUMENT',
                availability='school',sourceUrl=source['url'],sourceIds=[],sections=[],
                originalName=source['name'],sourceLinks=[])
        target=groups[key]
        target['sourceIds'].append(source['id'])
        target['sections']=sorted(set(target['sections']+source['sections']))
        target['sourceLinks'].append(dict(url=source['url'],label=' / '.join(source['sections'])))
    return list(groups.values())
