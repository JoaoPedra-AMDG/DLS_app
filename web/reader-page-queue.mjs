// Prioritise the page being read, then render a small buffer around it.
// Keeping only that buffer avoids retaining a full high-resolution book in RAM.
export function createPageQueue({ load, release, onError = () => {}, concurrency = 2 }) {
  let wanted = [];
  const active = new Map(), ready = new Set(), failed = new Set();
  function pump() {
    for (const key of wanted) {
      if (active.size >= concurrency) break;
      if (active.has(key) || ready.has(key) || failed.has(key)) continue;
      const controller = new AbortController();
      active.set(key, controller);
      Promise.resolve().then(() => load(key, controller.signal)).then(() => {
        if (!controller.signal.aborted && wanted.includes(key)) ready.add(key);
        else release(key);
      }).catch(error => {
        release(key);
        if (!controller.signal.aborted && wanted.includes(key)) {
          failed.add(key);
          onError(key, error);
        }
      }).finally(() => {
        active.delete(key);
        pump();
      });
    }
  }
  return {
    setWanted(keys) {
      wanted = [...new Set(keys)];
      for (const [key, controller] of active) if (!wanted.includes(key)) controller.abort();
      for (const key of ready) if (!wanted.includes(key)) { ready.delete(key); release(key); }
      for (const key of failed) if (!wanted.includes(key)) failed.delete(key);
      pump();
    },
  };
}

export function nearbyPages(current, total, firstVisible = current, lastVisible = current) {
  const visible = Array.from({ length: lastVisible - firstVisible + 1 }, (_, index) => firstVisible + index);
  return [...new Set([current, ...visible, lastVisible + 1, firstVisible - 1, lastVisible + 2])]
    .filter(page => page >= 1 && page <= total);
}
