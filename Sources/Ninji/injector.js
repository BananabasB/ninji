/* Sources/Ninji/injector.js
 * Copied into app resources so WebView can inject it at runtime.
 * Simple CSS-only userstyle injector: inject Catppuccin Mocha tokens as :root variables.
 */
(function(){
  const css = `:root {
  --color-bg: #1E1E2E;
  --color-surface: #11111B;
  --color-muted: #7287A1;
  --color-text: #CAD3F5;
  --color-primary: #89B4FA;
  --color-accent: #94E2D5;
  --color-success: #ABE9B3;
  --color-warning: #F9E2AF;
  --color-danger: #F38BA8;
  --color-border: #313244;
}`;

  try{
    const id = 'userstyle-catppuccin';
    if(!document.getElementById(id)){
      const s = document.createElement('style');
      s.id = id;
      s.textContent = css;
      document.documentElement.appendChild(s);
      console.log('userstyle (bundled): Catppuccin CSS injected');
    }
  }catch(e){ console.error('userstyle inject error', e); }

  return; // no runtime mapping
})();
 * Copied into app resources so WebView can inject it at runtime.
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

  // Fallback map derived from the hashed variables you provided in the web app CSS.
  const knownHashedColors = {
    '--_1hr2ce07': '#FFFFFF',
    '--_1hr2ce08': '#111111',
    '--_1hr2ce09': '#282828',
    '--_1hr2ce0a': '#3C3C3C',
    '--_1hr2ce0b': '#E60012',
    '--_1hr2ce0c': '#006BFF',
    '--_1hr2ce0d': '#F7CB00',
    '--_1hr2ce0e': '#00A000',
    '--_1hr2ce0f': '#F4F4F41A',
    '--_1hr2ce0g': '#1A1A1AB8',
    '--_1hr2ce0h': '#1A1A1AA3',
    '--_1hr2ce0i': '#00000099',
    '--_1hr2ce0j': '#00000099',
    '--_1hr2ce0k': '#00000000',
    '--_1hr2ce0l': '#000000cb',
    '--_1hr2ce0m': '#FF4128',
    '--_1hr2ce0n': '#1D1D1D',
    '--_1hr2ce0o': '#F4F4F40A',
    '--_1hr2ce0p': '#1F1F1F',
    '--_1hr2ce0q': '#F4F4F414',
    '--_1hr2ce0r': '#F4F4F41A',
    '--_1hr2ce0s': '#F4F4F429',
    '--_1hr2ce0t': '#F4F4F41A',
    '--_1hr2ce0u': '#1111111A',
    '--_1hr2ce0v': '#F4F4F433',
    '--_1hr2ce0w': '#F4F4F426',
    '--_1hr2ce0x': '#11111100',
    '--_1hr2ce0y': '#1111110d',
    '--_1hr2ce0z': '#11111133',
    '--_1hr2ce010': '#11111159',
    '--_1hr2ce011': '#11111180',
    '--_1hr2ce012': '#28282800',
    '--_1hr2ce013': '#282828',
    '--_1hr2ce014': '#1D1D1D00',
    '--_1hr2ce015': '#1D1D1D',
    '--_1hr2ce016': '#006BFF4D',
    '--_1hr2ce017': '#606060',
    '--_1hr2ce018': '#303030'
  };

  // A best-effort semantic guess mapping from common colors to tokens — used when we map the hashed vars directly
  const colorToTokenGuess = {
    '#ffffff': '--color-text',
    '#111111': '--color-bg',
    '#282828': '--color-surface',
    '#3c3c3c': '--color-border',
    '#e60012': '--color-danger',
    '#006bff': '--color-primary',
    '#006bff4d': '--color-primary',
    '#f7cb00': '--color-warning',
    '#00a000': '--color-success',
    '#ff4128': '--color-danger'
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

    // Build a fallback normalized map from knownHashedColors
    const fallbackValueMap = {};
    for(const [hv, hex] of Object.entries(knownHashedColors)){
      try{
        const normHex = normalize(hex);
        (fallbackValueMap[normHex] = fallbackValueMap[normHex] || []).push(hv);
      }catch(e){ /* ignore */ }
    }

    for(const [token, val] of Object.entries(theme)){
      const norm = normalize(val);
      let vars = (valueMap[norm] || []).filter(hv => hv !== token); // avoid self-mapping

      // If no vars found by computed-style, try fallbackValueMap (from provided hex list)
      if(vars.length === 0 && fallbackValueMap[norm]){
        vars = fallbackValueMap[norm].slice();
      }

      // If still empty, try best-effort guess: map known hexes whose normalized hex matches token guess
      if(vars.length === 0){
        const guessed = [];
        for(const [hv, hex] of Object.entries(knownHashedColors)){
          const key = hex.toLowerCase();
          const guess = colorToTokenGuess[key];
          if(guess === token) guessed.push(hv);
        }
        if(guessed.length) vars = guessed.slice();
      }

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
