import { getDocument, GlobalWorkerOptions } from './vendor/pdfjs/build/pdf.min.mjs';
import { attachReaderGestures } from './reader-gestures.mjs';

GlobalWorkerOptions.workerSrc = new URL('./vendor/pdfjs/build/pdf.worker.min.mjs', import.meta.url).href;
const params = new URLSearchParams(location.search);
const $ = id => document.getElementById(id);
if (params.get('embedded') === '1') $('standalone-header').hidden = true;
const title = params.get('title') || 'For Rosa · PDF';
$('title').textContent = title;
document.title = `${title} · For Rosa`;
const viewportElement = $('viewport');
let pdf, current = Math.max(1, Number.parseInt(params.get('page'), 10) || 1);
let zoom = 1, generation = 0, activeTask, fittedWidth = 0, fittedHeight = 0;

function showStatus() {
  if (pdf) $('status').textContent = `Page ${current} of ${pdf.numPages} · ${Math.round(zoom * 100)}%`;
}
function sizePreview() {
  const canvas = $('canvas');
  canvas.style.width = `${Math.floor(fittedWidth * zoom)}px`;
  canvas.style.height = `${Math.floor(fittedHeight * zoom)}px`;
}
function setZoom(value, clientX, clientY) {
  if (!fittedWidth) return;
  const page = $('page'), before = page.getBoundingClientRect();
  const x = (clientX - before.left) / before.width;
  const y = (clientY - before.top) / before.height;
  zoom = Math.max(1, Math.min(4, value));
  sizePreview();
  const after = page.getBoundingClientRect();
  viewportElement.scrollLeft += after.left + x * after.width - clientX;
  viewportElement.scrollTop += after.top + y * after.height - clientY;
  showStatus();
}
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
    const fit = Math.min(1.65, Math.max(1, viewportElement.clientWidth - 16) / unit.width);
    fittedWidth = unit.width * fit;
    fittedHeight = unit.height * fit;
    const viewport = page.getViewport({ scale: fit * zoom });
    // Keep high zoom usable on phones with limited canvas memory.
    const ratio = Math.min(devicePixelRatio || 1, 2, 8192 / viewport.width, 8192 / viewport.height,
      Math.sqrt(16000000 / (viewport.width * viewport.height)));
    const canvas = $('canvas');
    canvas.width = Math.floor(viewport.width * ratio);
    canvas.height = Math.floor(viewport.height * ratio);
    sizePreview();
    canvas.setAttribute('aria-label', `${title}, page ${pageNumber} of ${pdf.numPages}`);
    activeTask = page.render({ canvasContext: canvas.getContext('2d'), viewport, transform: ratio === 1 ? null : [ratio, 0, 0, ratio, 0, 0] });
    await activeTask.promise;
    if (sequence !== generation) return;
    activeTask = null;
    showStatus();
    const content = await page.getTextContent();
    if (sequence === generation) $('page-text').textContent = content.items.map(item => item.str + (item.hasEOL ? '\n' : ' ')).join('') || 'This page is a scan. Read the original page image or download the PDF.';
  } catch (error) {
    if (sequence !== generation || error.name === 'RenderingCancelledException') return;
    $('status').textContent = 'This page could not render. Swipe to another page or use Download.';
  }
}
function move(amount) {
  if (!pdf) return;
  const next = Math.max(1, Math.min(pdf.numPages, current + amount));
  if (next === current) return;
  current = next;
  zoom = 1;
  viewportElement.scrollLeft = viewportElement.scrollTop = 0;
  $('page-text').textContent = '';
  renderPage();
}
attachReaderGestures(viewportElement, { getZoom: () => zoom, setZoom, move, render: renderPage });
document.addEventListener('keydown', event => {
  if (event.target.closest('a, button, input, textarea, select') || event.ctrlKey || event.metaKey || event.altKey) return;
  if (['ArrowRight', 'PageDown', 'ArrowLeft', 'PageUp'].includes(event.key)) {
    event.preventDefault();
    move(['ArrowRight', 'PageDown'].includes(event.key) ? 1 : -1);
  }
  if (['+', '=', '-', '0'].includes(event.key)) {
    event.preventDefault();
    const bounds = viewportElement.getBoundingClientRect();
    setZoom(event.key === '0' ? 1 : zoom + (event.key === '-' ? -0.25 : 0.25), bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
    renderPage();
  }
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
  pdf = await getDocument({ url: file.href, cMapUrl: new URL('./vendor/pdfjs/cmaps/', import.meta.url).href, cMapPacked: true, standardFontDataUrl: new URL('./vendor/pdfjs/standard_fonts/', import.meta.url).href, isEvalSupported: false }).promise;
  current = Math.min(current, pdf.numPages);
  await renderPage();
} catch (_) {
  $('status').textContent = 'The paper could not load. Check your connection, then go Back and try again.';
}
