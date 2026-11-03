"""Create the independently authored 50-mark study memo for uploaded paper 23.

Run locally with ReportLab and pypdf. CI validates the committed PDF and manifest.
The source PDF is never modified; no school marking memorandum was supplied.
"""
import hashlib
import json
import shutil
from io import BytesIO
from pathlib import Path
from xml.sax.saxutils import escape

from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import (
    Flowable, PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle,
)
from reportlab.lib.utils import ImageReader

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'assets/papers/life-2022-november-section-a-answer-booklet-supplement.pdf'
SOURCE_SHA = '24b1ac3f07e5468b9ae1257f52a201a1862ecb69af08f7615eb9a67e904d6c22'
FILENAME = 'life-2022-november-section-a-study-memo.pdf'
OUTPUT = ROOT/'output/pdf'/FILENAME
GREEN = colors.HexColor('#28735C')
INK = colors.HexColor('#20322C')
MUTED = colors.HexColor('#53655D')
PALE = colors.HexColor('#EBF4EF')
LINE = colors.HexColor('#CFDFD5')
WIDTH = A4[0]-84
styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='MemoTitle',fontName='Helvetica-Bold',fontSize=20,leading=24,textColor=INK,spaceAfter=7))
styles.add(ParagraphStyle(name='MemoSub',fontName='Helvetica',fontSize=10.5,leading=15,textColor=MUTED,spaceAfter=9))
styles.add(ParagraphStyle(name='MemoBody',fontName='Helvetica',fontSize=10,leading=14,textColor=INK,spaceAfter=6))
styles.add(ParagraphStyle(name='MemoSmall',fontName='Helvetica',fontSize=8.3,leading=11.5,textColor=MUTED,spaceAfter=5))
styles.add(ParagraphStyle(name='MemoHead',fontName='Helvetica-Bold',fontSize=13,leading=17,textColor=GREEN,spaceBefore=12,spaceAfter=8))
styles.add(ParagraphStyle(name='MemoCell',fontName='Helvetica',fontSize=9.7,leading=13,textColor=INK))
styles.add(ParagraphStyle(name='MemoCellBold',parent=styles['MemoCell'],fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='MemoCentre',parent=styles['MemoCellBold'],alignment=TA_CENTER))


def p(text, style='MemoBody'):
    return Paragraph(escape(text).replace('\n','<br/>'),styles[style])


def table(rows, widths, header=True):
    cells=[[p(str(c),'MemoCellBold' if header and r==0 else 'MemoCell') for c in row] for r,row in enumerate(rows)]
    t=Table(cells,colWidths=widths,hAlign='LEFT',repeatRows=1 if header else 0)
    t.setStyle(TableStyle([
        ('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),
        ('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),7),
        ('BOTTOMPADDING',(0,0),(-1,-1),7),('LINEBELOW',(0,0),(-1,-1),0.4,LINE),
        *([('BACKGROUND',(0,0),(-1,0),PALE)] if header else []),
    ]))
    return t


class CellFigure(Flowable):
    """Reproduce the source micrograph; add only the paper's assessed letters."""
    def __init__(self, raw):
        super().__init__()
        self.image=ImageReader(BytesIO(raw))
        self.width=244
        self.height=299

    def draw(self):
        scale=218/452
        self.canv.drawImage(self.image,0,0,width=218,height=605*scale)
        self.canv.setFont('Helvetica-Bold',11)
        for letter,y in [('E',130),('A',245),('B',345),('C',423)]:
            self.canv.drawString(225,(605-y)*scale-3,letter)


class CycleLabels(Flowable):
    """Location guide matching the source diagram; not a time-proportion plot."""
    def __init__(self):
        super().__init__()
        self.width=WIDTH
        self.height=152

    def draw(self):
        c=self.canv
        boxes=[(15,91,190,49,'G2 - Growth phase 2','Upper-left / before mitosis'),
               (305,91,190,49,'Mitosis + cytokinesis','Already printed on the paper'),
               (305,5,190,49,'G1 - Growth phase 1','Right / lower-right blue region'),
               (15,5,190,49,'S - Synthesis','Left / lower-left pink region')]
        for x,y,w,h,title,sub in boxes:
            c.setFillColor(PALE);c.setStrokeColor(LINE);c.roundRect(x,y,w,h,8,fill=1,stroke=1)
            c.setFillColor(INK);c.setFont('Helvetica-Bold',10);c.drawCentredString(x+w/2,y+29,title)
            c.setFillColor(MUTED);c.setFont('Helvetica',8.5);c.drawCentredString(x+w/2,y+13,sub)
        def arrow(x1,y1,x2,y2):
            import math
            c.setStrokeColor(GREEN);c.setLineWidth(1.4);c.line(x1,y1,x2,y2)
            a=math.atan2(y2-y1,x2-x1)
            for d in [-0.45,0.45]:c.line(x2,y2,x2-6*math.cos(a+d),y2-6*math.sin(a+d))
        arrow(210,115,299,115);arrow(400,85,400,60)
        arrow(299,29,211,29);arrow(110,60,110,85)


def footer(c, doc):
    c.saveState()
    c.setStrokeColor(LINE);c.setLineWidth(.5);c.line(42,40,A4[0]-42,40)
    c.setFont('Helvetica',8);c.setFillColor(MUTED)
    c.drawString(42,27,'For Rosa | Generated study memo - not official school marking guidelines')
    c.drawRightString(A4[0]-42,27,f'{doc.page} / 3')
    c.restoreState()


def main():
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==SOURCE_SHA
    source=PdfReader(SOURCE)
    OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    story=[p('Life Sciences - Grade 10','MemoTitle'),
           p('November 2022 | Section A | Study memo | 50 marks','MemoSub'),
           p('Generated worked answers for the supplied six-page Answer Booklet. This is an independently prepared study memo, not an official DLSHCCH memorandum.','MemoSmall'),
           p('Suggested marking: follow the printed allocations. Accept equivalent scientific wording. Explanations below support revision; they do not add marks to multiple-choice or matching answers.','MemoSmall'),
           p('Question 1 - Multiple choice [10]','MemoHead')]
    q1=[
        ('1.1','C','Respiration transfers energy to ATP: ADP combines with inorganic phosphate to form ATP.','2'),
        ('1.2','B','Species is the most specific of the four categories listed.','2'),
        ('1.3','C','The nucleus contains genetic information and regulates cell activities; "cell functioning" is the best option.','2'),
        ('1.4','B','Root hairs increase the surface area for uptake of water and mineral ions.','2'),
        ('1.5','C','Facilitated diffusion is passive movement down a concentration gradient through specific membrane proteins.','2'),
    ]
    story += [table([('No.','Answer','Explanation','Marks')]+q1,[38,62,WIDTH-145,45]),
              p('Question 2 - Biological terms [10]','MemoHead')]
    q2=[
        ('2.1','Anaphase','Sister chromatids separate and move towards opposite poles.','2'),
        ('2.2','Cellular respiration','Chemical energy is transferred from food molecules to ATP; energy is not created from nothing.','2'),
        ('2.3','Granum','One stack of thylakoids. The plural is grana.','2'),
        ('2.4','Peristalsis','Coordinated waves of muscular contraction move material along the digestive tract.','2'),
        ('2.5','Food chain','A single feeding pathway showing the direction of energy transfer.','2'),
    ]
    story += [table([('No.','Answer','Explanation','Marks')]+q2,[38,108,WIDTH-191,45]),PageBreak(),
              p('Question 3 - Cell micrograph [10]','MemoHead'),
              p('The letters below correspond to those on page 4 of the supplied booklet. Unlettered arrows are not assessed.','MemoSmall')]
    q3=[
        p('3.1  Plant cell. [2]','MemoCellBold'),
        p('A cell wall and chloroplasts support this identification.','MemoSmall'),
        p('3.2  E: vacuole. [2]','MemoCellBold'),
        p('The pale compartment indicated by E is a vacuole.','MemoSmall'),
        p('3.3  C: nucleolus function. [2]','MemoCellBold'),
        p('Ribosomal RNA (rRNA) is synthesised (1), and ribosomal subunits are assembled (1). Accept "makes ribosomes" as an equivalent concise answer.','MemoSmall'),
        p('3.4  False. [2]','MemoCellBold'),
        p('B is the cell/plasma membrane: it is selectively permeable, so not all substances can pass freely. The question asks only for true or false.','MemoSmall'),
        p('3.5  A: chloroplast. [2]','MemoCellBold'),
        p('Its internal thylakoid membranes are visible.','MemoSmall'),
    ]
    t=Table([[CellFigure(source.pages[3].images[0].data),q3]],colWidths=[254,WIDTH-254])
    t.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),0),('RIGHTPADDING',(0,0),(-1,-1),6)]))
    story += [t,Spacer(1,7),
              p('Important distinction: C points to the dark nucleolus inside the nucleus. "Controls cell activities" describes the nucleus as a whole, not the nucleolus.','MemoSmall'),
              p('Question 4 - Matching columns [10]','MemoHead')]
    q4=[
        ('4.1','A','Habitat: the place or environment in which an organism lives.','2'),
        ('4.2','E','Biotic: the living components of an ecosystem.','2'),
        ('4.3','D','Niche: an organism\'s ecological role and resource use.','2'),
        ('4.4','G','Stroma: the fluid-filled region of a chloroplast outside the thylakoids.','2'),
        ('4.5','C','Diffusion: net movement of particles down a concentration gradient.','2'),
    ]
    story += [table([('No.','Letter','Meaning','Marks')]+q4,[38,62,WIDTH-145,45]),
              p('Distractors: B describes the mitochondrial matrix. F refers to stromatolites, not stroma.','MemoSmall'),PageBreak(),
              p('Question 5 - Cell cycle [10]','MemoHead'),
              p('Diagram labels [3]','MemoCellBold'),
              p('Award 1 mark for each label placed in the correct region. This location guide matches the regions in the original diagram; box size does not show time spent in a phase.','MemoBody'),CycleLabels(),Spacer(1,7),
              p('G1: growth and normal activity after division. S: DNA replication. G2: further growth, checking and preparation before mitosis. G1, S and G2 together form interphase; G0 is not one of the three requested labels.','MemoSmall'),
              p('5.1  Importance of cell regeneration [3]','MemoHead'),
              p('Award 1 mark for each distinct point, to a maximum of 3:\n1. It replaces dead, worn-out or lost cells.\n2. It repairs damaged tissues and helps wounds heal.\n3. It restores or maintains the normal functioning of tissues and organs.'),
              p('Accept a clearly explained equivalent biological benefit. Do not award a second mark for simply repeating the same point.','MemoSmall'),
              p('5.2  Phase occupying most of the cell\'s life [1]','MemoHead'),
              p('Interphase. (1) This includes G1, S and G2; it is not a stage of mitosis.'),
              p('5.3  Why the daughter cells are duplicates [3]','MemoHead'),
              p('1. DNA is replicated during the S phase of interphase. (1)\n2. During mitosis, sister chromatids separate and are distributed equally to the two nuclei. (1)\n3. Each daughter cell therefore normally receives the same chromosome number and genetic information as the original cell. (1)'),
              p('Total: Q1 10 + Q2 10 + Q3 10 + Q4 10 + Q5 10 = 50 marks.','MemoHead'),
              Spacer(1,6),
              Paragraph('Source: supplied DLSHCCH Grade 10 Life Science November 2022 Section A Answer Booklet (6 PDF pages). Organelle terminology cross-check: <link href="https://openstax.org/books/biology-2e/pages/4-3-eukaryotic-cells" color="#28735C">OpenStax Biology 2e, 4.3 Eukaryotic Cells</link>. Prepared for For Rosa on 3 November 2026.',styles['MemoSmall'])]
    assert sum(int(row[-1]) for row in q1+q2+q4)+5*2+(3+3+1+3)==50
    doc=SimpleDocTemplate(str(OUTPUT),pagesize=A4,rightMargin=42,leftMargin=42,topMargin=40,bottomMargin=56,title='Grade 10 Life Sciences - November 2022 Section A Study Memo',author='For Rosa',subject='Generated study memo, 50 marks; not official school marking guidelines')
    doc.build(story,onFirstPage=footer,onLaterPages=footer)
    pdf=PdfReader(OUTPUT)
    assert len(pdf.pages)==3, f'Expected 3 pages, got {len(pdf.pages)}'
    text='\n'.join(page.extract_text() or '' for page in pdf.pages)
    assert all(ref in text for ref in ['1.1','1.2','1.3','1.4','1.5','2.1','2.2','2.3','2.4','2.5','3.1','3.2','3.3','3.4','3.5','4.1','4.2','4.3','4.4','4.5','5.1','5.2','5.3'])
    assert 'nucleolus' in text and '50 marks' in text
    published=ROOT/'assets/papers'/FILENAME
    shutil.copyfile(OUTPUT,published)
    manifest=[dict(id='life-2022-section-a-study-memo',subject='life',year=2022,
        title='November Section A study memo - 2022',kind='memo',memo=None,
        note='Generated study memo with suggested marks. Not official school marking guidelines.',
        file=FILENAME,pages=len(pdf.pages),sha256=hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
        originals=[],generated=True,sourcePaper='23',sourceSha256=SOURCE_SHA,totalMarks=50,
        sourcePageMap={'1':1,'2':1,'3':1,'4':2,'5':2,'6':3})]
    (ROOT/'assets/generated_memos.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Created',OUTPUT,';',len(pdf.pages),'pages; 50 marks; source 23 matched.')


if __name__=='__main__':
    main()
