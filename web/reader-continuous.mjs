import { getDocument, GlobalWorkerOptions } from './vendor/pdfjs/build/pdf.min.mjs';
import { attachReaderGestures } from './reader-touch.mjs';
import { createPageQueue, nearbyPages } from './reader-page-queue.mjs';

GlobalWorkerOptions.workerSrc = new URL('./vendor/pdfjs/build/pdf.worker.min.mjs', import.meta.url).href;
const params = new URLSearchParams(location.search);
const $ = id => document.getElementById(id);
if (params.get('embedded') === '1') $('standalone-header').hidden = true;
const title = params.get('title') || 'For Rosa · PDF';
$('title').textContent = title;
document.title = `${title} · For Rosa`;
const viewportElement = $('viewport'), surface = $('surface');
let pdf, current = Math.max(1, Number.parseInt(params.get('page'), 10) || 1);
let zoom = 1, revision = 0, preview = false, updateFrame;
const pages = [];

function showStatus() {
  if (!pdf) return;
  const status = `Page ${current} of ${pdf.numPages} · ${Math.round(zoom * 100)}%`;
  const text = pages[current - 1]?.text || '';
  if ($('status').textContent !== status) $('status').textContent = status;
  if ($('page-text').textContent !== text) $('page-text').textContent = text;
}
function sizePage(record) {
  const fit = Math.min(1.65, Math.max(1, viewportElement.clientWidth - 16) / record.width);
  record.fit = fit;
  record.element.style.width = `${Math.floor(record.width * fit * zoom)}px`;
  record.element.style.height = `${Math.floor(record.height * fit * zoom)}px`;
}
function pageAt(y) {
  // Placeholders retain their heights even when offscreen canvases are released.
  let low = 0, high = pages.length - 1;
  while (low < high) {
    const middle = Math.floor((low + high + 1) / 2);
    if (pages[middle].element.offsetTop <= y) low = middle;
    else high = middle - 1;
  }
  return pages[low];
}
function withAnchor(clientX, clientY, change) {
  if (!pages.length) return;
  const bounds = viewportElement.getBoundingClientRect();
  const record = pageAt(viewportElement.scrollTop + clientY - bounds.top);
  const before = record.element.getBoundingClientRect();
  const x = (clientX - before.left) / before.width;
  const y = (clientY - before.top) / before.height;
  change();
  const after = record.element.getBoundingClientRect();
  viewportElement.scrollLeft += after.left + x * after.width - clientX;
  viewportElement.scrollTop += after.top + y * after.height - clientY;
}
function setZoom(value, clientX, clientY) {
  if (!pages.length) return;
  preview = true;
  withAnchor(clientX, clientY, () => {
    zoom = Math.max(1, Math.min(4, value));
    pages.forEach(sizePage);
  });
  showStatus();
}
function releasePage(key) {
  const record = pages[Number(key.split(':')[0]) - 1];
  if (record?.key !== key) return;
  record.canvas?.remove();
  if (record.canvas) record.canvas.width = record.canvas.height = 0;
  record.canvas = undefined;
  record.key = undefined;
  record.placeholder.textContent = `Page ${record.number}`;
  record.placeholder.hidden = false;
}
const queue = createPageQueue({
  async load(key, signal) {
    const number = Number(key.split(':')[0]), record = pages[number - 1];
    const page = await pdf.getPage(number);
    if (signal.aborted) return;
    const unit = page.getViewport({ scale: 1 });
    if (record.width !== unit.width || record.height !== unit.height) {
      const bounds = viewportElement.getBoundingClientRect();
      withAnchor(bounds.left + bounds.width / 2, bounds.top, () => {
        record.width = unit.width;
        record.height = unit.height;
        sizePage(record);
      });
      scheduleUpdate();
    }
    record.canvas?.remove();
    if (record.canvas) record.canvas.width = record.canvas.height = 0;
    const canvas = document.createElement('canvas');
    record.canvas = canvas;
    record.key = key;
    record.placeholder.textContent = `Loading page ${number}…`;
    record.placeholder.hidden = false;
    canvas.hidden = true;
    canvas.setAttribute('aria-label', `${title}, page ${number} of ${pdf.numPages}`);
    record.element.append(canvas);
    const viewport = page.getViewport({ scale: record.fit * zoom });
    // Divide a 16-million-pixel budget across visible pages and their buffer.
    const bounds = viewportElement.getBoundingClientRect();
    const firstVisible = pageAt(viewportElement.scrollTop).number;
    const lastVisible = pageAt(viewportElement.scrollTop + bounds.height).number;
    const bufferedCount = nearbyPages(current, pdf.numPages, firstVisible, lastVisible).length;
    const ratio = Math.min(devicePixelRatio || 1, 2, 8192 / viewport.width, 8192 / viewport.height,
      Math.sqrt((16000000 / Math.max(4, bufferedCount)) / (viewport.width * viewport.height)));
    canvas.width = Math.floor(viewport.width * ratio);
    canvas.height = Math.floor(viewport.height * ratio);
    const task = page.render({ canvasContext: canvas.getContext('2d'), viewport, transform: ratio === 1 ? null : [ratio, 0, 0, ratio, 0, 0] });
    const cancel = () => task.cancel();
    signal.addEventListener('abort', cancel, { once: true });
    try {
      await task.promise;
      if (signal.aborted || record.key !== key) return;
      canvas.hidden = false;
      record.placeholder.hidden = true;
      try {
        const content = await page.getTextContent();
        record.text = content.items.map(item => item.str + (item.hasEOL ? '\n' : ' ')).join('') || 'This page is a scan. Read the page image or download the PDF.';
      } catch (_) {
        record.text = 'Text is unavailable for this page. Read the page image or download the PDF.';
      }
      if (current === number) showStatus();
    } finally {
      signal.removeEventListener('abort', cancel);
    }
  },
  release: releasePage,
  onError(key) {
    const record = pages[Number(key.split(':')[0]) - 1];
    record.placeholder.textContent = `Page ${record.number} could not load. Scroll away and back to retry, or use Download.`;
  },
});
function updateVisiblePages() {
  updateFrame = undefined;
  if (!pdf || !pages.length) return;
  const readingLine = viewportElement.scrollTop + viewportElement.clientHeight / 2;
  current = pageAt(readingLine).number;
  showStatus();
  if (!preview) {
    const firstVisible = pageAt(viewportElement.scrollTop).number;
    const lastVisible = pageAt(viewportElement.scrollTop + viewportElement.clientHeight).number;
    queue.setWanted(nearbyPages(current, pdf.numPages, firstVisible, lastVisible).map(number => `${number}:${revision}`));
  }
}
function scheduleUpdate() {
  if (!updateFrame) updateFrame = requestAnimationFrame(updateVisiblePages);
}
function sharpenPages() {
  preview = false;
  revision++;
  updateVisiblePages();
}
viewportElement.addEventListener('scroll', scheduleUpdate, { passive: true });
attachReaderGestures(viewportElement, { getZoom: () => zoom, setZoom, render: sharpenPages });
document.addEventListener('keydown', event => {
  if (event.target.closest('a, button, input, textarea, select') || event.ctrlKey || event.metaKey || event.altKey) return;
  if (['+', '=', '-', '0'].includes(event.key)) {
    event.preventDefault();
    const bounds = viewportElement.getBoundingClientRect();
    setZoom(event.key === '0' ? 1 : zoom + (event.key === '-' ? -0.25 : 0.25), bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
    sharpenPages();
  }
});
let resizeTimer;
window.addEventListener('resize', () => {
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(() => {
    const bounds = viewportElement.getBoundingClientRect();
    withAnchor(bounds.left, bounds.top, () => pages.forEach(sizePage));
    sharpenPages();
  }, 150);
});

try {
  const file = new URL(params.get('file') || '', document.baseURI);
  const allowed = new URL('assets/assets/papers/', document.baseURI);
  if (file.origin !== location.origin || !file.pathname.startsWith(allowed.pathname) || !file.pathname.toLowerCase().endsWith('.pdf')) throw new Error('Invalid paper URL');
  file.hash = '';
  $('download').href = file.href;
  $('download').download = file.pathname.split('/').pop();
  pdf = await getDocument({ url: file.href, cMapUrl: new URL('./vendor/pdfjs/cmaps/', import.meta.url).href, cMapPacked: true, standardFontDataUrl: new URL('./vendor/pdfjs/standard_fonts/', import.meta.url).href, isEvalSupported: false }).promise;
  current = Math.min(current, pdf.numPages);
  const first = await pdf.getPage(current), unit = first.getViewport({ scale: 1 });
  for (let number = 1; number <= pdf.numPages; number++) {
    const element = document.createElement('section'), placeholder = document.createElement('span');
    element.className = 'pdf-page';
    element.setAttribute('aria-label', `Page ${number}`);
    placeholder.className = 'page-placeholder';
    placeholder.textContent = `Page ${number}`;
    element.append(placeholder);
    surface.append(element);
    const record = { number, element, placeholder, width: unit.width, height: unit.height };
    pages.push(record);
    sizePage(record);
  }
  viewportElement.scrollTop = pages[current - 1].element.offsetTop;
  updateVisiblePages();
} catch (_) {
  $('status').textContent = 'The paper could not load. Check your connection, then go Back and try again.';
}
