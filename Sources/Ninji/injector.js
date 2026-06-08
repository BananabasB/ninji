/* Sources/Ninji/injector.js
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

  const applyTheme = () => {
    const valueMap = buildValueMap();
    const styleLines = [];

    // define canonical semantic tokens first
    for(const [k,v] of Object.entries(theme)) styleLines.push(`${k}: ${v} !important`);

    // for each semantic token, find any existing hashed vars that match the same computed value
    const mappings = {};
    for(const [token, val] of Object.entries(theme)){
      const norm = normalize(val);
      const vars = valueMap[norm] || [];
      mappings[token] = vars.slice();
      for(const hv of vars) styleLines.push(`${hv}: var(${token}) !important`);
    }

    let s = document.getElementById('theme-injector');
    if(!s){ s = document.createElement('style'); s.id = 'theme-injector'; document.head.appendChild(s); }
    s.textContent = `:root{${styleLines.join(';')}}`;

    // Runtime logging to help debug injection
    try{
      console.log(`theme-injector: applied ${Object.keys(theme).length} semantic tokens, ${styleLines.length} style rules`);
      let anyMatched = false;
      for(const [token, vars] of Object.entries(mappings)){
        if(vars.length) { anyMatched = true; console.log(`theme-injector: ${token} mapped to: ${vars.join(', ')}`); }
      }
      if(!anyMatched) console.log('theme-injector: no hashed variables matched by color — semantic tokens added only');
    }catch(e){ /* ignore logging errors */ }
  };

  const safeApply = () => {
    try{
      if(document.readyState === 'loading') document.addEventListener('DOMContentLoaded', applyTheme);
      else applyTheme();
    }catch(e){ console.error('theme-injector error', e); }
  };

  safeApply();
  const ob = new MutationObserver(()=>applyTheme());
  ob.observe(document.documentElement, { attributes: true, childList: true, subtree: true });

  // expose for debugging
  window.__themeInjector = { applyTheme };
})();
