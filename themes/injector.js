/* themes/injector.js
 * Runtime theme injector for webview-based apps.
 * - Builds a color-value → CSS variable map from computed styles
 * - Sets semantic tokens (Catppuccin Mocha sample) on :root
 * - Maps any matching hashed vars to those semantic tokens
 * - Reapplies on DOM mutation (debounced and change-guarded to avoid spam)
 */
(function(){
  const normalize = (c) => {
    try{
      const d = document.createElement('div');
      d.style.color = c;
      d.style.display = 'none';
      document.body.appendChild(d);
      const comp = getComputedStyle(d).color;
      document.body.removeChild(d);
      return comp.replace(/\s+/g,'');
    }catch(e){ return c; }
  };

  const buildValueMap = () => {
    const css = getComputedStyle(document.documentElement);
    const m = {};
    for(let i=0;i<css.length;i++){
      const name = css[i];
      if(!name.startsWith('--')) continue;
      const raw = css.getPropertyValue(name).trim();
      if(!raw) continue;
      const norm = normalize(raw) || raw;
      (m[norm] = m[norm] || []).push(name);
    }
    return m;
  };

  // Catppuccin Mocha (sample) tokens — tweak to taste
  const theme = {
    '--color-bg': '#1E1E2E',
    '--color-surface': '#11111B',
    '--color-muted': '#7287A1',
    '--color-text': '#CAD3F5',
    '--color-primary': '#89B4FA',
    '--color-accent': '#94E2D5',
    '--color-success': '#ABE9B3',
    '--color-warning': '#F9E2AF',
    '--color-danger': '#F38BA8',
    '--color-border': '#313244'
  };

  let lastContent = null;
  let lastMappingsJson = null;
  let applyTimeout = null;
  let applyCount = 0;
  let observer = null;
  const MAX_APPLY = 2; // after this number of real updates, stop observing to avoid loops

  const applyTheme = () => {
    const valueMap = buildValueMap();
    const styleLines = [];

    // define canonical semantic tokens first
    for(const [k,v] of Object.entries(theme)) styleLines.push(`${k}: ${v} !important`);

    // for each semantic token, find any existing hashed vars that match the same computed value
    const mappings = {};
    for(const [token, val] of Object.entries(theme)){
      const norm = normalize(val);
      const vars = (valueMap[norm] || []).filter(hv => hv !== token); // avoid self-mapping
      mappings[token] = vars.slice();
      for(const hv of vars) styleLines.push(`${hv}: var(${token}) !important`);
    }

    const content = `:root{${styleLines.join(';')}}`;
    let s = document.getElementById('theme-injector');
    if(!s){ s = document.createElement('style'); s.id = 'theme-injector'; document.head.appendChild(s); }

    // Only update if content actually changed to avoid triggering infinite mutation loops
    if(s.textContent === content) return;
    s.textContent = content;

    applyCount++;
    // If we've applied enough times, disconnect observer to prevent repeated reapplications
    if(applyCount >= MAX_APPLY && observer) {
      try { observer.disconnect(); } catch(e) {}
      observer = null;
    }

    // Runtime logging to help debug injection (only when changed)
    try{
      console.log(`theme-injector: applied ${Object.keys(theme).length} semantic tokens, ${styleLines.length} style rules`);
      let anyMatched = false;
      for(const [token, vars] of Object.entries(mappings)){
        if(vars.length) { anyMatched = true; console.log(`theme-injector: ${token} mapped to: ${vars.join(', ')}`); }
      }
      if(!anyMatched) console.log('theme-injector: no hashed variables matched by color — semantic tokens added only');
    }catch(e){ /* ignore logging errors */ }

    lastContent = content;
    lastMappingsJson = JSON.stringify(mappings);
  };

  const scheduleApply = (delay = 120) => {
    if(applyCount >= MAX_APPLY) return;
    if(applyTimeout) clearTimeout(applyTimeout);
    applyTimeout = setTimeout(() => { try{ applyTheme(); } catch(e){ console.error('theme-injector apply error', e); } applyTimeout = null; }, delay);
  };

  const safeApply = () => {
    try{
      if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', () => scheduleApply(10));
      else scheduleApply(10);
    }catch(e){ console.error('theme-injector error', e); }
  };

  safeApply();
  observer = new MutationObserver(() => scheduleApply());
  observer.observe(document.documentElement, { attributes: true, childList: true, subtree: true });

  // expose for debugging
  window.__themeInjector = { applyTheme, scheduleApply };
})();
