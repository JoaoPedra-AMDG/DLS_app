// Pointer events work for touch, pens and mouse dragging without browser zoom.
export function attachReaderGestures(viewport, { getZoom, setZoom, move, render }) {
  const points = new Map();
  let single, pinch, multiple = false, wheelTimer;
  const midpoint = ([a, b]) => ({ x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 });
  const distance = ([a, b]) => Math.hypot(a.x - b.x, a.y - b.y);
  const position = event => ({ x: event.clientX, y: event.clientY });
  const beginSingle = point => {
    single = { ...point, left: viewport.scrollLeft, top: viewport.scrollTop,
      atLeft: viewport.scrollLeft <= 2,
      atRight: viewport.scrollLeft >= viewport.scrollWidth - viewport.clientWidth - 2 };
  };
  const beginPinch = () => {
    const pair = [...points.values()];
    pinch = { distance: distance(pair), zoom: getZoom(), center: midpoint(pair) };
    multiple = true;
  };
  viewport.addEventListener('pointerdown', event => {
    if (event.button !== 0) return;
    clearTimeout(wheelTimer);
    if (!points.size) { multiple = false; beginSingle(position(event)); }
    points.set(event.pointerId, position(event));
    viewport.setPointerCapture(event.pointerId);
    if (points.size === 2) beginPinch();
  });
  viewport.addEventListener('pointermove', event => {
    if (!points.has(event.pointerId)) return;
    points.set(event.pointerId, position(event));
    if (points.size === 2 && pinch) {
      const pair = [...points.values()], center = midpoint(pair);
      if (pinch.distance > 0) setZoom(pinch.zoom * distance(pair) / pinch.distance, pinch.center.x, pinch.center.y);
      viewport.scrollLeft -= center.x - pinch.center.x;
      viewport.scrollTop -= center.y - pinch.center.y;
      // Rebase after each move so the content stays beneath the fingers.
      pinch = { distance: distance(pair), zoom: getZoom(), center };
    } else if (points.size === 1 && single) {
      viewport.scrollLeft = single.left - (event.clientX - single.x);
      viewport.scrollTop = single.top - (event.clientY - single.y);
    }
  });
  const finish = (event, cancelled = false) => {
    if (!points.has(event.pointerId)) return;
    points.delete(event.pointerId);
    if (!points.size) {
      const dx = event.clientX - single.x, dy = event.clientY - single.y;
      if (!cancelled && !multiple && Math.abs(dx) >= 60 && Math.abs(dx) > Math.abs(dy) * 1.35 &&
          (dx < 0 ? single.atRight : single.atLeft)) move(dx < 0 ? 1 : -1);
      if (multiple) render(); // Replace the live bitmap preview with a sharp page.
      single = pinch = undefined;
    } else if (points.size === 1) {
      beginSingle([...points.values()][0]);
      pinch = undefined;
    } else if (points.size === 2) beginPinch();
  };
  viewport.addEventListener('pointerup', event => finish(event));
  viewport.addEventListener('pointercancel', event => finish(event, true));
  viewport.addEventListener('lostpointercapture', event => finish(event, true));
  viewport.addEventListener('wheel', event => {
    if (!event.ctrlKey) return; // Ordinary trackpad scrolling still pans the page.
    event.preventDefault();
    if (points.size) return;
    setZoom(getZoom() * Math.exp(-event.deltaY * 0.01), event.clientX, event.clientY);
    clearTimeout(wheelTimer);
    wheelTimer = setTimeout(render, 120);
  }, { passive: false });
}
