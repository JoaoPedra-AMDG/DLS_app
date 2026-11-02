import { getDocument, GlobalWorkerOptions } from './vendor/pdfjs/build/pdf.min.mjs';

GlobalWorkerOptions.workerSrc = new URL('./vendor/pdfjs/build/pdf.worker.min.mjs', import.meta.url).href;
const params = new URLSearchParams(location.search);
const $ = id => document.getElementById(id);
if (params.get('embedded') === '1') $('standalone-header').hidden = true;
const title = params.get('title') || 'For Rosa · PDF';
$('title').textContent = title;
document.title = `${title} · For Rosa`;
let pdf, current = Math.max(1, Number.parseInt(params.get('page'), 10) || 1);
let zoom = 1, generation = 0, activeTask;
const controls = ['previous', 'next', 'zoom-out', 'zoom-in', 'fit', 'page-number'];

async function renderPage() {
  if (!pdf) return;
  const sequence = ++generation;
  const previousTask = activeTask;
  if (previousTask) {
    previousTask.cancel();
    try { await previousTask.promise; } catch { /* A replaced page is intentional. */ }
  }
  if (sequence !== generation) return;
  $('status').textContent = `Loading page ${current} of ${pdf.numPages}…`;
  try {
    const pageNumber = current;
    const page = await pdf.getPage(pageNumber);
    if (sequence !== generation) return;
    const unit = page.getViewport({ scale: 1 });
    const available = Math.max(240, $('viewport').clientWidth - 28);
    const scale = Math.min(1.65, available / unit.width) * zoom;
    const viewport = page.getViewport({ scale });
    const ratio = Math.min(devicePixelRatio || 1, 2);
    const canvas = $('canvas');
    canvas.width = Math.floor(viewport.width * ratio);
    canvas.height = Math.floor(viewport.height * ratio);
    canvas.style.width = `${Math.floor(viewport.width)}px`;
    canvas.style.height = `${Math.floor(viewport.height)}px`;
    canvas.setAttribute('aria-label', `${title}, page ${pageNumber} of ${pdf.numPages}`);
    activeTask = page.render({ canvasContext: canvas.getContext('2d'), viewport, transform: ratio === 1 ? null : [ratio, 0, 0, ratio, 0, 0] });
    await activeTask.promise;
    if (sequence !== generation) return;
    activeTask = null;
    $('page-number').value = pageNumber;
    $('page-number').max = pdf.numPages;
    $('page-count').textContent = ` / ${pdf.numPages}`;
    $('previous').disabled = pageNumber <= 1;
    $('next').disabled = pageNumber >= pdf.numPages;
    $('status').textContent = `Page ${pageNumber} of ${pdf.numPages} · ${Math.round(zoom * 100)}% of fitted width`;
    const content = await page.getTextContent();
    if (sequence === generation) $('page-text').textContent = content.items.map(item => item.str + (item.hasEOL ? '\n' : ' ')).join('') || 'This page is a scan. Read the original page image above or download the original PDF.';
  } catch (error) {
    if (sequence !== generation || error.name === 'RenderingCancelledException') return;
    $('status').textContent = 'This page could not render. Try another page or download the original PDF.';
    $('fallback').hidden = false;
  }
}
function move(amount) {
  if (!pdf) return;
  current = Math.max(1, Math.min(pdf.numPages, current + amount));
  $('viewport').scrollLeft = 0;
  renderPage();
}
$('previous').addEventListener('click', () => move(-1));
$('next').addEventListener('click', () => move(1));
$('page-form').addEventListener('submit', event => {
  event.preventDefault();
  if (!pdf) return;
  current = Math.max(1, Math.min(pdf.numPages, Number.parseInt($('page-number').value, 10) || 1));
  renderPage();
});
$('zoom-in').addEventListener('click', () => { zoom = Math.min(3, zoom + 0.25); renderPage(); });
$('zoom-out').addEventListener('click', () => { zoom = Math.max(0.5, zoom - 0.25); renderPage(); });
$('fit').addEventListener('click', () => { zoom = 1; renderPage(); });
document.addEventListener('keydown', event => {
  if (event.target.tagName === 'INPUT') return;
  if (event.key === 'ArrowRight') { event.preventDefault(); move(1); }
  if (event.key === 'ArrowLeft') { event.preventDefault(); move(-1); }
});
let resizeTimer;
window.addEventListener('resize', () => { clearTimeout(resizeTimer); resizeTimer = setTimeout(renderPage, 150); });

try {
  const file = new URL(params.get('file') || '', document.baseURI);
  const allowed = new URL('assets/assets/papers/', document.baseURI);
  if (file.origin !== location.origin || !file.pathname.startsWith(allowed.pathname) || !file.pathname.toLowerCase().endsWith('.pdf')) throw new Error('Invalid paper URL');
  file.hash = '';
  $('download').href = file.href;
  $('download').download = file.pathname.split('/').pop();
  $('fallback').href = file.href;
  pdf = await getDocument({ url: file.href, cMapUrl: new URL('./vendor/pdfjs/cmaps/', import.meta.url).href, cMapPacked: true, standardFontDataUrl: new URL('./vendor/pdfjs/standard_fonts/', import.meta.url).href, isEvalSupported: false }).promise;
  current = Math.min(current, pdf.numPages);
  await renderPage();
} catch (_) {
  for (const id of controls) $(id).disabled = true;
  $('status').textContent = 'The paper could not load. Check your connection, then return to your study library and try again.';
  if ($('fallback').href) $('fallback').hidden = false;
}
