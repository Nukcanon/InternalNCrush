// Web updates follow the deployed build, not the Windows release label.
(() => {
  GODOT_CONFIG.args = [...(GODOT_CONFIG.args || [])];
  if (!GODOT_CONFIG.args.includes('--')) GODOT_CONFIG.args.push('--');
  GODOT_CONFIG.args.push('--no-update-check');
  const current = GODOT_CONFIG.executable;
  let checking = false;
  async function check(force = false) {
    if (checking) return;
    checking = true;
    const abort = new AbortController();
    const timeout = setTimeout(() => abort.abort(), 5000);
    try {
      const url = new URL('build.json', location.href);
      url.searchParams.set('_check', Date.now());
      const response = await fetch(url, { cache: 'no-store', signal: abort.signal });
      if (!response.ok) return;
      const build = await response.json();
      if (!/^game-[a-zA-Z0-9_-]+$/.test(build.executable || '')) return;
      if (build.executable === current && !force) return;
      const key = 'inc-web-update:' + build.executable;
      // A temporarily stale CDN page must not cause an endless reload loop.
      try {
        if (!force && Date.now() - Number(sessionStorage.getItem(key) || 0) < 120000) return;
        sessionStorage.setItem(key, String(Date.now()));
      } catch (_) { if (new URL(location.href).searchParams.get('build') === build.executable) return; }
      const next = new URL(location.href);
      next.searchParams.set('build', build.executable);
      next.searchParams.set('_refresh', Date.now());
      location.replace(next.href);
      return await new Promise(() => {});
    } catch (_) {
      // Offline/failed checks leave the installed game playable.
    } finally {
      clearTimeout(timeout);
      checking = false;
    }
  }
  window.incRefreshGame = () => check(true);
  window.incUpdateReady = check();
  setInterval(() => { if (!document.hidden) check(); }, 60000);
  document.addEventListener('visibilitychange', () => { if (!document.hidden) check(); });
})();

// Do not let modified gameplay clicks trigger browser menus, drag or navigation.
(() => {
  const canvas = document.getElementById('canvas');
  if (!canvas) return;
  for (const type of ['mousedown', 'mouseup', 'click', 'dblclick', 'auxclick', 'contextmenu', 'dragstart']) {
    canvas.addEventListener(type, event => event.preventDefault(), { passive: false });
  }
  canvas.addEventListener('wheel', event => event.preventDefault(), { passive: false });
  document.addEventListener('keydown', event => {
    if (document.pointerLockElement !== canvas && document.activeElement !== canvas) return;
    if ((event.ctrlKey || event.metaKey) && ['w', 's', 'a', 'd'].includes(event.key.toLowerCase())) event.preventDefault();
  }, { capture: true });
})();
