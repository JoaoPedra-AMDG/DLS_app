from pathlib import Path
import subprocess
from PIL import Image, ImageOps, ImageDraw

root = Path(__file__).resolve().parents[1]
out = root / 'tmp' / 'previews'
out.mkdir(parents=True, exist_ok=True)
poppler = Path(r'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin\pdftoppm.exe')
ids = [3,4,7,8,10,11,14,16,18,24,25,28,40,42,44]
thumbs=[]
for n in ids:
    for page in [1,2]:
        dest=out/f'{n}-{page}'
        subprocess.run([str(poppler),'-f',str(page),'-l',str(page),'-scale-to','1000','-singlefile','-png',str(root/f'{n}.pdf'),str(dest)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
        im=Image.open(str(dest)+'.png').convert('RGB')
        im.thumbnail((400,540))
        tile=Image.new('RGB',(420,580),'#eeeeee'); tile.paste(im,((420-im.width)//2,30))
        ImageDraw.Draw(tile).text((10,8),f'{n}.pdf / page {page}',fill='black')
        thumbs.append(tile)
for i in range(0,len(thumbs),6):
    sheet=Image.new('RGB',(1260,1160),'white')
    for j,tile in enumerate(thumbs[i:i+6]): sheet.paste(tile,((j%3)*420,(j//3)*580))
    sheet.save(out/f'contact-{i//6}.jpg')
print('Rendered',len(thumbs),'pages')
