// Pointer events work for touch, pens and mouse dragging without browser zoom.
export function attachReaderGestures(viewport, { getZoom, setZoom, render,
  requestFrame = callback => requestAnimationFrame(callback), cancelFrame = frame => cancelAnimationFrame(frame) }) {
  const points = new Map();
  let single, pinch, multiple = false, wheelTimer, inertia;
  const midpoint = ([a, b]) => ({ x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 });
  const distance = ([a, b]) => Math.hypot(a.x - b.x, a.y - b.y);
  const position = event => ({ x: event.clientX, y: event.clientY, time: event.timeStamp, type: event.pointerType });
  const beginSingle = point => {
    single = { ...point, left: viewport.scrollLeft, top: viewport.scrollTop, last: point, vx: 0, vy: 0 };
  };
  function stopMomentum() {
    if (inertia !== undefined) cancelFrame(inertia);
    inertia = undefined;
  }
  function startMomentum(time, vx, vy) {
    let previous = time;
    const step = now => {
      const dt = Math.min(32, Math.max(0, now - previous));
      previous = now;
      if (!dt) { inertia = requestFrame(step); return; }
      const left = viewport.scrollLeft, top = viewport.scrollTop;
      viewport.scrollLeft += vx * dt;
      viewport.scrollTop += vy * dt;
      vx = viewport.scrollLeft === left ? 0 : vx * Math.pow(0.93, dt / 16);
      vy = viewport.scrollTop === top ? 0 : vy * Math.pow(0.93, dt / 16);
      if (Math.abs(vx) + Math.abs(vy) > 0.02) inertia = requestFrame(step);
      else inertia = undefined;
    };
    inertia = requestFrame(step);
  }
  const beginPinch = () => {
    const pair = [...points.values()];
    pinch = { distance: distance(pair), zoom: getZoom(), center: midpoint(pair) };
    multiple = true;
  };
  viewport.addEventListener('pointerdown', event => {
    if (event.button !== 0) return;
    stopMomentum();
    if (wheelTimer) { clearTimeout(wheelTimer); wheelTimer = undefined; render(); }
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
      const left = viewport.scrollLeft, top = viewport.scrollTop;
      viewport.scrollLeft = single.left - (event.clientX - single.x);
      viewport.scrollTop = single.top - (event.clientY - single.y);
      const dt = event.timeStamp - single.last.time;
      if (dt > 0 && dt <= 80) {
        single.vx = 0.65 * Math.max(-3, Math.min(3, (viewport.scrollLeft - left) / dt)) + 0.35 * single.vx;
        single.vy = 0.65 * Math.max(-3, Math.min(3, (viewport.scrollTop - top) / dt)) + 0.35 * single.vy;
      } else single.vx = single.vy = 0;
      single.last = position(event);
    }
  });
  const finish = (event, cancelled = false) => {
    if (!points.has(event.pointerId)) return;
    points.delete(event.pointerId);
    if (!points.size) {
      if (!cancelled && !multiple && single.type === 'touch' && event.timeStamp - single.last.time < 80) {
        startMomentum(event.timeStamp, single.vx, single.vy);
      }
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
    stopMomentum();
    if (!event.ctrlKey) return; // Ordinary trackpad scrolling still pans the page.
    event.preventDefault();
    if (points.size) return;
    setZoom(getZoom() * Math.exp(-event.deltaY * 0.01), event.clientX, event.clientY);
    clearTimeout(wheelTimer);
    wheelTimer = setTimeout(() => { wheelTimer = undefined; render(); }, 120);
  }, { passive: false });
}
