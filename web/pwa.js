// Installation is always initiated by the student, never automatically.
let installPrompt;
const standalone = () => window.matchMedia('(display-mode: standalone)').matches || navigator.standalone === true;
window.addEventListener('beforeinstallprompt', event => {
  event.preventDefault();
  installPrompt = event;
});
window.addEventListener('appinstalled', () => { installPrompt = undefined; });
window.forRosaInstall = async () => {
  if (standalone()) return 'installed';
  if (!installPrompt) return 'manual';
  const prompt = installPrompt;
  installPrompt = undefined;
  await prompt.prompt();
  const result = await prompt.userChoice;
  return result.outcome === 'accepted' ? 'accepted' : 'dismissed';
};

if ('serviceWorker' in navigator && window.isSecureContext) {
  window.addEventListener('load', async () => {
    try {
      const registration = await navigator.serviceWorker.register(new URL('sw.js', document.baseURI), { scope: './', updateViaCache: 'none' });
      const checkUpdate = () => registration.update().catch(() => {});
      document.addEventListener('visibilitychange', () => { if (!document.hidden) checkUpdate(); });
      setInterval(checkUpdate, 5 * 60 * 1000);
      registration.addEventListener('updatefound', () => {
        const worker = registration.installing;
        worker?.addEventListener('statechange', () => {
          if (worker.state === 'installed' && navigator.serviceWorker.controller && !document.getElementById('update-notice')) {
            const banner = document.createElement('div');
            banner.id = 'update-notice';
            banner.setAttribute('role', 'status');
            banner.style.cssText = 'position:fixed;bottom:90px;left:16px;right:16px;z-index:99999;padding:15px;background:#292744;color:white;border-radius:12px;font:14px system-ui;box-shadow:0 4px 24px #0003;display:flex;gap:12px;align-items:center;justify-content:center;flex-wrap:wrap';
            const message = document.createElement('span');
            message.textContent = 'A new version of For Rosa is ready.';
            const button = document.createElement('button');
            button.textContent = 'Reload to update';
            button.style.cssText = 'padding:10px 14px;border:0;border-radius:8px;background:#e4dfff;color:#25233d;cursor:pointer';
            button.addEventListener('click', () => location.reload());
            const later = document.createElement('button');
            later.textContent = 'Later';
            later.style.cssText = 'padding:10px;background:transparent;border:0;color:white;cursor:pointer';
            later.addEventListener('click', () => banner.remove());
            banner.append(message, button, later);
            document.body.append(banner);
          }
        });
      });
    } catch (_) { /* Installation can still be offered by supporting browsers. */ }
  });
}
