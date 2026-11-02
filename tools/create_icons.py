"""Draw the app's own book mark at each platform's required icon sizes."""
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(__file__).resolve().parents[1]
def icon(size,dest):
 im=Image.new('RGB',(512,512),'#6654d9');d=ImageDraw.Draw(im)
 d.rounded_rectangle((56,56,456,456),radius=104,fill='#7d6be1')
 d.polygon([(125,163),(238,188),(256,210),(274,188),(387,163),(387,348),(274,373),(256,395),(238,373),(125,348)],fill='#faf8ff')
 d.line([(256,214),(256,375)],fill='#c7bcf4',width=9)
 for y in [225,265,305]:
  d.line([(150,y),(224,y+16)],fill='#c7bcf4',width=9)
  d.line([(288,y+16),(362,y)],fill='#c7bcf4',width=9)
 d.ellipse((346,98,400,152),fill='#ffd782')
 im.resize((size,size),Image.Resampling.LANCZOS).save(root/dest)
for size,name in [(192,'Icon-192'),(512,'Icon-512'),(192,'Icon-maskable-192'),(512,'Icon-maskable-512')]:icon(size,f'web/icons/{name}.png')
icon(48,'web/favicon.png')
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:icon(size,f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
print('App icons generated.')
