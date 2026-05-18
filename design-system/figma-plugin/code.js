// ================================================================
// DJTilbud Design System — Figma Generator Plugin  v2.0
// Components rendered visually to match the actual Flutter widgets.
// ================================================================

function hex(h) {
  const n = parseInt(h.replace('#',''), 16);
  return { r:((n>>16)&255)/255, g:((n>>8)&255)/255, b:(n&255)/255 };
}
function hexA(h, a) { const c = hex(h); return { r:c.r, g:c.g, b:c.b, a:a }; }

// ── TOKENS ──────────────────────────────────────────────────────

const LIGHT = {
  'Brand/Primary':             '#D1F366',
  'Brand/Primary Hover':       '#B8DC4B',
  'Brand/Primary Active':      '#5A731A',
  'Brand/On Primary':          '#141627',
  'Brand/Accent':              '#66D0F2',
  'Brand/Accent Soft':         '#D0D4E7',
  'Brand/On Accent':           '#141627',
  'Background/Canvas':         '#F8F8F8',
  'Background/Surface':        '#FFFFFF',
  'Background/Elevated':       '#FFFFFF',
  'Background/Input':          '#F3F3F3',
  'Background/Input Hover':    '#DDDDDD',
  'Text/Primary':              '#141627',
  'Text/Secondary':            '#626577',
  'Text/Muted':                '#9A9CAB',
  'Text/On Dark':              '#FFFFFF',
  'Border/Subtle':             '#DDDDDD',
  'Border/Strong':             '#626577',
  'State/Success':             '#5A731A',
  'State/Warning':             '#FFD365',
  'State/Danger':              '#EC502C',
  'State/Info':                '#66D0F2',
  'Trust/Verified':            '#66D0F2',
  'Trust/Verified Soft':       '#D0D4E7',
  'Availability/Available':    '#5A731A',
  'Availability/Limited':      '#FFD365',
  'Availability/Unavailable':  '#9A9CAB',
};

const DARK = {
  'Brand/Primary':             '#D1F366',
  'Brand/Primary Hover':       '#B8DC4B',
  'Brand/Primary Active':      '#D1F366',
  'Brand/On Primary':          '#141627',
  'Brand/Accent':              '#66D0F2',
  'Brand/Accent Soft':         '#1C1F37',
  'Brand/On Accent':           '#141627',
  'Background/Canvas':         '#111827',
  'Background/Surface':        '#1F2937',
  'Background/Elevated':       '#374151',
  'Background/Input':          '#1F2937',
  'Background/Input Hover':    '#374151',
  'Text/Primary':              '#F9FAFB',
  'Text/Secondary':            '#D1D5DB',
  'Text/Muted':                '#9CA3AF',
  'Text/On Dark':              '#F9FAFB',
  'Border/Subtle':             '#374151',
  'Border/Strong':             '#4B5563',
  'State/Success':             '#22C55E',
  'State/Warning':             '#F59E0B',
  'State/Danger':              '#EF4444',
  'State/Info':                '#3B82F6',
  'Trust/Verified':            '#2DD4BF',
  'Trust/Verified Soft':       '#134E4A',
  'Availability/Available':    '#22C55E',
  'Availability/Limited':      '#F59E0B',
  'Availability/Unavailable':  '#6B7280',
};

const SPACING = { S0:0, S1:4, S2:8, S3:12, S4:16, S6:24, S8:32, S12:48 };
const RADIUS  = { SM:8, MD:12, LG:16, Pill:9999 };
const MOTION  = { Fast:120, Normal:180, Slow:260 };

const TEXT_STYLES = [
  { name:'Display/Large',  size:32, weight:700, tracking:-0.5, lineHeight:120 },
  { name:'Display/Medium', size:24, weight:700, tracking:-0.3, lineHeight:125 },
  { name:'Heading/Large',  size:20, weight:600, tracking:-0.2, lineHeight:130 },
  { name:'Heading/Medium', size:18, weight:600, tracking:0,    lineHeight:130 },
  { name:'Heading/Small',  size:16, weight:600, tracking:0,    lineHeight:140 },
  { name:'Body/Large',     size:16, weight:400, tracking:0,    lineHeight:150 },
  { name:'Body/Medium',    size:14, weight:400, tracking:0,    lineHeight:150 },
  { name:'Body/Small',     size:12, weight:400, tracking:0,    lineHeight:150 },
  { name:'Label/Large',    size:14, weight:500, tracking:0,    lineHeight:140 },
  { name:'Label/Medium',   size:13, weight:500, tracking:0,    lineHeight:140 },
  { name:'Label/Small',    size:12, weight:500, tracking:0,    lineHeight:140 },
];

// NOTE: change 'Semi Bold' → 'SemiBold' if Figma throws font errors
const W = { 400:'Regular', 500:'Medium', 600:'Semi Bold', 700:'Bold' };

// ── PRIMITIVE HELPERS ────────────────────────────────────────────

function rect(parent, w, h, x, y, fillColor, opts = {}) {
  const r = figma.createRectangle();
  r.resize(w, h);
  r.x = x; r.y = y;
  r.fills = fillColor ? [{ type:'SOLID', color:fillColor, opacity: opts.opacity !== undefined ? opts.opacity : 1 }] : [];
  if (opts.radius !== undefined) r.cornerRadius = opts.radius;
  if (opts.stroke) {
    r.strokes = [{ type:'SOLID', color:opts.stroke, opacity: opts.strokeOpacity !== undefined ? opts.strokeOpacity : 1 }];
    r.strokeWeight = opts.strokeWidth !== undefined ? opts.strokeWidth : 1;
    r.strokeAlign = 'INSIDE';
  }
  if (opts.shadow) {
    r.effects = [{ type:'DROP_SHADOW', color:hexA('#0F172A', 0.06), offset:{x:0,y:1}, radius:2, spread:0, visible:true, blendMode:'NORMAL' }];
  }
  parent.appendChild(r);
  return r;
}

function ellipse(parent, w, h, x, y, fillColor, opts = {}) {
  const e = figma.createEllipse();
  e.resize(w, h);
  e.x = x; e.y = y;
  e.fills = fillColor ? [{ type:'SOLID', color:fillColor }] : [];
  if (opts.stroke) {
    e.strokes = [{ type:'SOLID', color:opts.stroke }];
    e.strokeWeight = opts.strokeWidth !== undefined ? opts.strokeWidth : 1;
  }
  parent.appendChild(e);
  return e;
}

function text(parent, chars, size, weight, color, x, y, opts = {}) {
  const t = figma.createText();
  t.fontName = { family:'Inter', style: W[weight] || 'Regular' };
  t.fontSize = size;
  t.characters = chars;
  t.fills = [{ type:'SOLID', color }];
  t.x = x; t.y = y;
  if (opts.opacity !== undefined) t.opacity = opts.opacity;
  parent.appendChild(t);
  return t;
}

function frame(parent, w, h, x, y, fillColor, opts = {}) {
  const f = figma.createFrame();
  f.resize(w, h);
  f.x = x; f.y = y;
  f.fills = fillColor ? [{ type:'SOLID', color:fillColor }] : [];
  if (opts.radius !== undefined) f.cornerRadius = opts.radius;
  if (opts.stroke) {
    f.strokes = [{ type:'SOLID', color:opts.stroke }];
    f.strokeWeight = opts.strokeWidth !== undefined ? opts.strokeWidth : 1;
  }
  if (opts.clip) f.clipsContent = true;
  parent.appendChild(f);
  return f;
}

// Section header with lime underline
function sectionHeader(page, title, y) {
  text(page, title, 28, 700, hex('#141627'), 0, y);
  rect(page, 700, 2, 0, y + 42, hex('#D1F366'));
  return y + 72;
}

// Component wrapper card — dark label at top, white content area
function componentCard(page, title, subtitle, x, y, w, h) {
  const card = frame(page, w, h + 56, x, y, hex('#FFFFFF'), { radius:16, stroke:hex('#DDDDDD') });
  // Header bar
  rect(card, w, 44, 0, 0, hex('#F8F8F8'));
  text(card, title, 13, 600, hex('#141627'), 16, 14);
  if (subtitle) text(card, subtitle, 10, 400, hex('#9A9CAB'), 16, 30);
  return card; // content starts at y=56 inside card
}

// ── COMPONENT RENDERERS ──────────────────────────────────────────
// Each returns the pixel height of the rendered content area

function renderButton(card, cx, cy) {
  // Primary button — pill, lime, dark text, h=32
  rect(card, 120, 32, cx, cy, hex('#D1F366'), { radius:9999 });
  text(card, 'Tilbyd', 14, 600, hex('#141627'), cx + 30, cy + 8);

  // Secondary — lime tint 10%, lime text
  rect(card, 120, 32, cx + 136, cy, hex('#D1F366'), { radius:9999, opacity:0.1 });
  text(card, 'Tilbyd', 14, 600, hex('#5A731A'), cx + 166, cy + 8);

  // Tertiary — white, dark border
  rect(card, 120, 32, cx + 272, cy, hex('#FFFFFF'), { radius:9999, stroke:hex('#626577') });
  text(card, 'Annuller', 14, 600, hex('#141627'), cx + 299, cy + 8);

  // Ghost
  rect(card, 80, 32, cx + 408, cy, null, { radius:9999 });
  text(card, 'Se mere', 14, 400, hex('#626577'), cx + 412, cy + 8);

  // Sizes row
  rect(card, 80, 28, cx, cy + 48, hex('#D1F366'), { radius:9999 });
  text(card, 'SM', 13, 600, hex('#141627'), cx + 26, cy + 56);

  rect(card, 80, 32, cx + 96, cy + 46, hex('#D1F366'), { radius:9999 });
  text(card, 'MD', 14, 600, hex('#141627'), cx + 120, cy + 54);

  rect(card, 80, 40, cx + 192, cy + 42, hex('#D1F366'), { radius:9999 });
  text(card, 'LG', 15, 600, hex('#141627'), cx + 216, cy + 52);

  // Disabled
  rect(card, 80, 32, cx + 288, cy + 46, hex('#DDDDDD'), { radius:9999 });
  text(card, 'Lukket', 14, 600, hex('#9A9CAB'), cx + 305, cy + 54);

  return 108;
}

function renderInput(card, cx, cy) {
  // Label
  text(card, 'Hvad hedder du?', 14, 500, hex('#141627'), cx, cy);
  // Input field — pill, inputBg
  rect(card, 280, 44, cx, cy + 22, hex('#F3F3F3'), { radius:9999 });
  text(card, 'Indtast dit navn...', 14, 400, hex('#9A9CAB'), cx + 20, cy + 36);

  // Second field with value
  text(card, 'Email', 14, 500, hex('#141627'), cx, cy + 82);
  rect(card, 280, 44, cx, cy + 104, hex('#F3F3F3'), { radius:9999, stroke:hex('#D1F366'), strokeWidth:2 });
  text(card, 'victor@djtilbud.dk', 14, 400, hex('#141627'), cx + 20, cy + 118);

  // Error state
  text(card, 'Telefon', 14, 500, hex('#141627'), cx, cy + 164);
  rect(card, 280, 44, cx, cy + 186, hex('#F3F3F3'), { radius:9999, stroke:hex('#EC502C'), strokeWidth:2 });
  text(card, 'Ugyldigt nummer', 12, 400, hex('#EC502C'), cx, cy + 236);

  return 256;
}

function renderChip(card, cx, cy) {
  // Default (unselected)
  rect(card, 70, 34, cx, cy, hex('#FFFFFF'), { radius:9999, stroke:hex('#626577') });
  text(card, 'Pop', 13, 500, hex('#141627'), cx + 21, cy + 10);

  // Selected
  rect(card, 84, 34, cx + 86, cy, hex('#D1F366'), { radius:9999, stroke:hex('#D1F366') });
  text(card, 'House', 13, 500, hex('#141627'), cx + 104, cy + 10);

  // Tinted (read-only genre tag)
  rect(card, 88, 24, cx, cy + 50, hex('#D1F366'), { radius:9999, opacity:0.15 });
  text(card, '70er/80er', 11, 600, hex('#5A731A'), cx + 8, cy + 56);

  rect(card, 58, 24, cx + 96, cy + 50, hex('#D1F366'), { radius:9999, opacity:0.15 });
  text(card, 'Disco', 11, 600, hex('#5A731A'), cx + 110, cy + 56);

  // With delete × icon
  rect(card, 96, 34, cx, cy + 92, hex('#FFFFFF'), { radius:9999, stroke:hex('#626577') });
  text(card, 'Bryllup ×', 13, 500, hex('#141627'), cx + 12, cy + 102);

  return 136;
}

function renderStatusBadge(card, cx, cy) {
  const badges = [
    { label:'Afventer svar', color:'#FFD365' },
    { label:'Aftale bekræftet', color:'#5A731A' },
    { label:'Tabt', color:'#EC502C' },
    { label:'Udbudt', color:'#66D0F2' },
  ];
  let bx = cx;
  for (const b of badges) {
    const tw = b.label.length * 6.5 + 16;
    rect(card, tw, 24, bx, cy, hex(b.color), { radius:9999, opacity:0.20, stroke:hex(b.color), strokeOpacity:0.55 });
    text(card, b.label, 11, 600, hex(b.color), bx + 8, cy + 6);
    bx += tw + 8;
  }

  // Full-width banner
  rect(card, 280, 32, cx, cy + 40, hex('#5A731A'), { radius:9999, opacity:0.25, stroke:hex('#5A731A'), strokeOpacity:0.55 });
  text(card, 'Aftale bekræftet — du spiller til dette event', 11, 600, hex('#5A731A'), cx + 12, cy + 50);

  return 80;
}

function renderSurface(card, cx, cy) {
  // Surface card container
  const surface = frame(card, 260, 100, cx, cy, hex('#FFFFFF'), { radius:16, stroke:hex('#DDDDDD') });
  surface.effects = [{ type:'DROP_SHADOW', color:hexA('#0F172A', 0.06), offset:{x:0,y:1}, radius:2, spread:0, visible:true, blendMode:'NORMAL' }];
  text(surface, 'Bryllup · 19. aug 2028', 14, 600, hex('#141627'), 16, 16);
  text(surface, 'Bygaden 1, Slangerup', 12, 400, hex('#626577'), 16, 38);
  text(surface, '48 gæster · 22:00–02:00', 12, 400, hex('#9A9CAB'), 16, 56);

  return 120;
}

function renderAvatar(card, cx, cy) {
  const sizes = [24, 32, 40, 56, 72];
  let ax = cx;
  for (const sz of sizes) {
    // Circle with lime-tint background
    ellipse(card, sz, sz, ax, cy + (72 - sz) / 2, hex('#D1F366'), {});
    card.children[card.children.length - 1].opacity = 0.12;
    // User icon approximation — small circle inside
    ellipse(card, sz * 0.28, sz * 0.28, ax + sz * 0.36, cy + (72 - sz) / 2 + sz * 0.18, hex('#5A731A'));
    // Body arc approximation
    rect(card, sz * 0.56, sz * 0.24, ax + sz * 0.22, cy + (72 - sz) / 2 + sz * 0.55, hex('#5A731A'), { radius:sz });
    text(card, `${sz}`, 10, 400, hex('#9A9CAB'), ax + sz * 0.1, cy + 78);
    ax += sz + 16;
  }
  return 96;
}

function renderSwitch(card, cx, cy) {
  // OFF state
  rect(card, 56, 32, cx, cy, hex('#DDDDDD'), { radius:9999 });
  ellipse(card, 24, 24, cx + 4, cy + 4, hex('#FFFFFF'));

  // ON state
  rect(card, 56, 32, cx + 80, cy, hex('#D1F366'), { radius:9999 });
  ellipse(card, 24, 24, cx + 80 + 28, cy + 4, hex('#FFFFFF'));

  // With labels
  text(card, 'Push notifikationer', 14, 600, hex('#141627'), cx, cy + 52);
  rect(card, 56, 32, cx + 224, cy + 48, hex('#D1F366'), { radius:9999 });
  ellipse(card, 24, 24, cx + 224 + 28, cy + 52, hex('#FFFFFF'));

  text(card, 'Slå lyd fra', 14, 600, hex('#141627'), cx, cy + 100);
  rect(card, 56, 32, cx + 224, cy + 96, hex('#DDDDDD'), { radius:9999 });
  ellipse(card, 24, 24, cx + 228, cy + 100, hex('#FFFFFF'));

  return 136;
}

function renderCheckbox(card, cx, cy) {
  // Unchecked
  rect(card, 24, 24, cx, cy, null, { radius:8, stroke:hex('#626577'), strokeWidth:2 });
  text(card, 'Jeg accepterer betingelserne', 14, 600, hex('#141627'), cx + 36, cy + 4);

  // Checked
  rect(card, 24, 24, cx, cy + 44, hex('#D1F366'), { radius:8, stroke:hex('#D1F366'), strokeWidth:2 });
  text(card, '✓', 13, 700, hex('#141627'), cx + 5, cy + 48);
  text(card, 'Send mig nyhedsbreve', 14, 600, hex('#141627'), cx + 36, cy + 48);

  // Disabled unchecked
  rect(card, 24, 24, cx, cy + 88, null, { radius:8, stroke:hex('#DDDDDD'), strokeWidth:2 });
  text(card, 'Ikke tilgængeligt', 14, 600, hex('#9A9CAB'), cx + 36, cy + 92);

  return 120;
}

function renderRadio(card, cx, cy) {
  // Unselected
  ellipse(card, 22, 22, cx, cy, null, { stroke:hex('#626577'), strokeWidth:2 });
  text(card, 'B-indkomst', 14, 400, hex('#141627'), cx + 30, cy + 4);

  // Selected
  ellipse(card, 22, 22, cx, cy + 40, null, { stroke:hex('#D1F366'), strokeWidth:2 });
  ellipse(card, 12, 12, cx + 5, cy + 45, hex('#D1F366'));
  text(card, 'A-indkomst', 14, 400, hex('#141627'), cx + 30, cy + 44);

  // Disabled
  ellipse(card, 22, 22, cx, cy + 80, null, { stroke:hex('#DDDDDD'), strokeWidth:2 });
  text(card, 'Virksomhed', 14, 400, hex('#9A9CAB'), cx + 30, cy + 84);

  return 108;
}

function renderDropdown(card, cx, cy) {
  // Closed state
  text(card, 'Genre', 14, 500, hex('#141627'), cx, cy);
  rect(card, 280, 44, cx, cy + 22, hex('#F3F3F3'), { radius:9999 });
  text(card, 'Vælg genre', 14, 400, hex('#9A9CAB'), cx + 20, cy + 36);
  text(card, '⌄', 18, 400, hex('#626577'), cx + 250, cy + 32);

  // With selection
  text(card, 'Event type', 14, 500, hex('#141627'), cx, cy + 82);
  rect(card, 280, 44, cx, cy + 104, hex('#F3F3F3'), { radius:9999 });
  text(card, 'Bryllup', 14, 400, hex('#141627'), cx + 20, cy + 118);
  text(card, '⌄', 18, 400, hex('#626577'), cx + 250, cy + 114);

  return 160;
}

function renderSlider(card, cx, cy) {
  // Track
  rect(card, 280, 4, cx, cy + 12, hex('#DDDDDD'), { radius:9999 });
  rect(card, 168, 4, cx, cy + 12, hex('#D1F366'), { radius:9999 });
  // Thumb
  ellipse(card, 24, 24, cx + 156, cy + 4, hex('#FFFFFF'), { stroke:hex('#D1F366'), strokeWidth:2 });

  text(card, '5.000 kr', 12, 500, hex('#141627'), cx, cy + 32);
  text(card, '10.000 kr', 12, 500, hex('#9A9CAB'), cx + 240, cy + 32);
  text(card, 'Budget: 7.500 kr', 13, 600, hex('#141627'), cx + 100, cy + 52);

  return 72;
}

function renderRangeSlider(card, cx, cy) {
  // Track
  rect(card, 280, 4, cx, cy + 12, hex('#DDDDDD'), { radius:9999 });
  rect(card, 140, 4, cx + 70, cy + 12, hex('#D1F366'), { radius:9999 });
  // Min thumb
  ellipse(card, 24, 24, cx + 58, cy + 4, hex('#FFFFFF'), { stroke:hex('#D1F366'), strokeWidth:2 });
  // Max thumb
  ellipse(card, 24, 24, cx + 196, cy + 4, hex('#FFFFFF'), { stroke:hex('#D1F366'), strokeWidth:2 });

  text(card, '0 kr', 12, 500, hex('#141627'), cx, cy + 32);
  text(card, '15.000 kr', 12, 500, hex('#9A9CAB'), cx + 236, cy + 32);
  text(card, '4.000 – 9.000 kr', 13, 600, hex('#141627'), cx + 90, cy + 52);

  return 72;
}

function renderSegmentedControl(card, cx, cy) {
  const labels = ['Åbne', 'Sendte', 'Vundet'];
  const totalW = 280, segW = totalW / 3;

  rect(card, totalW, 36, cx, cy, hex('#F3F3F3'), { radius:9999 });
  for (let i = 0; i < labels.length; i++) {
    if (i === 1) {
      // Selected segment
      rect(card, segW - 4, 28, cx + i * segW + 2, cy + 4, hex('#FFFFFF'), { radius:9999 });
      text(card, labels[i], 13, 600, hex('#141627'), cx + i * segW + 22, cy + 12);
    } else {
      text(card, labels[i], 13, 400, hex('#9A9CAB'), cx + i * segW + (i === 0 ? 24 : 20), cy + 12);
    }
  }

  return 56;
}

function renderTabBar(card, cx, cy) {
  rect(card, 320, 48, cx, cy, hex('#FFFFFF'), { stroke:hex('#DDDDDD') });
  const tabs = [
    { label:'Jobs', active:true },
    { label:'Kalender', active:false },
    { label:'Chat', active:false },
    { label:'Profil', active:false },
  ];
  const tabW = 320 / 4;
  for (let i = 0; i < tabs.length; i++) {
    const tx = cx + i * tabW;
    const clr = tabs[i].active ? hex('#141627') : hex('#9A9CAB');
    // Icon circle placeholder
    ellipse(card, 20, 20, tx + tabW / 2 - 10, cy + 6, tabs[i].active ? hex('#D1F366') : null, {});
    if (!tabs[i].active) {
      card.children[card.children.length - 1].opacity = 0;
    }
    text(card, tabs[i].label, 10, tabs[i].active ? 600 : 400, clr, tx + tabW / 2 - tabs[i].label.length * 3, cy + 34);
    // Active dot
    if (tabs[i].active) {
      rect(card, 24, 2, tx + tabW / 2 - 12, cy + 46, hex('#D1F366'), { radius:9999 });
    }
  }

  return 68;
}

function renderNavigationBar(card, cx, cy) {
  rect(card, 320, 64, cx, cy, hex('#FFFFFF'), { stroke:hex('#DDDDDD') });
  const tabs = [
    { icon:'⊙', label:'Jobs', active:true },
    { icon:'□', label:'Kalender', active:false },
    { icon:'◇', label:'Chat', active:false },
    { icon:'○', label:'Profil', active:false },
  ];
  const tabW = 320 / 4;
  for (let i = 0; i < tabs.length; i++) {
    const tx = cx + i * tabW + tabW / 2;
    const active = tabs[i].active;
    text(card, tabs[i].icon, 22, 400, active ? hex('#141627') : hex('#9A9CAB'), tx - 10, cy + 8);
    text(card, tabs[i].label, 10, active ? 600 : 400, active ? hex('#141627') : hex('#9A9CAB'), tx - tabs[i].label.length * 3, cy + 44);
  }

  return 84;
}

function renderToast(card, cx, cy) {
  const toasts = [
    { label:'Tilbud sendt!', color:'#5A731A' },
    { label:'Noget gik galt — prøv igen', color:'#EC502C' },
    { label:'Ny besked fra kunde', color:'#66D0F2' },
  ];
  let ty = cy;
  for (const t of toasts) {
    rect(card, 280, 40, cx, ty, hex('#141627'), { radius:12 });
    rect(card, 4, 24, cx + 12, ty + 8, hex(t.color), { radius:4 });
    text(card, t.label, 13, 500, hex('#F9FAFB'), cx + 24, ty + 12);
    ty += 52;
  }
  return ty - cy;
}

function renderInfoChip(card, cx, cy) {
  const chips = [
    { label:'48 gæster', icon:'👥' },
    { label:'Bryllup', icon:'💍' },
    { label:'22:00–02:00', icon:'🕙' },
    { label:'Nordsjælland', icon:'📍' },
  ];
  let ix = cx;
  let row2 = false;
  for (let i = 0; i < chips.length; i++) {
    if (i === 2) { ix = cx; row2 = true; }
    const rowY = cy + (row2 ? 44 : 0);
    const tw = chips[i].label.length * 7 + 36;
    rect(card, tw, 32, ix, rowY, hex('#F3F3F3'), { radius:9999 });
    text(card, chips[i].icon + ' ' + chips[i].label, 12, 500, hex('#626577'), ix + 10, rowY + 8);
    ix += tw + 8;
  }
  return 84;
}

// ── COMPONENT CATALOGUE ──────────────────────────────────────────

const CATALOGUE = [
  { name:'Button',            subtitle:'4 variants · 3 sizes',   render: renderButton,         w:520, h:124 },
  { name:'Input',             subtitle:'Normal · Focus · Error',  render: renderInput,          w:340, h:272 },
  { name:'Chip',              subtitle:'Default · Selected · Tinted · Delete', render: renderChip, w:280, h:152 },
  { name:'Info Chip',         subtitle:'Read-only metadata pills', render: renderInfoChip,      w:340, h:100 },
  { name:'Status Badge',      subtitle:'Inline · Banner',         render: renderStatusBadge,   w:480, h:100 },
  { name:'Surface',           subtitle:'Card container',          render: renderSurface,        w:300, h:136 },
  { name:'Avatar',            subtitle:'5 sizes · Placeholder',   render: renderAvatar,         w:420, h:112 },
  { name:'Switch',            subtitle:'On · Off · Labelled',     render: renderSwitch,         w:340, h:152 },
  { name:'Checkbox',          subtitle:'Checked · Unchecked · Disabled', render: renderCheckbox, w:340, h:136 },
  { name:'Radio',             subtitle:'Selected · Unselected · Disabled', render: renderRadio, w:280, h:124 },
  { name:'Dropdown',          subtitle:'Empty · With value',      render: renderDropdown,       w:340, h:176 },
  { name:'Slider',            subtitle:'Single value',            render: renderSlider,         w:340, h:88 },
  { name:'Range Slider',      subtitle:'Min + Max thumbs',        render: renderRangeSlider,    w:340, h:88 },
  { name:'Segmented Control', subtitle:'3 segments',              render: renderSegmentedControl, w:320, h:72 },
  { name:'Tab Bar',           subtitle:'4 tabs · active state',   render: renderTabBar,         w:360, h:84 },
  { name:'Navigation Bar',    subtitle:'Bottom nav · 4 items',    render: renderNavigationBar,  w:360, h:100 },
  { name:'Toast',             subtitle:'Success · Error · Info',  render: renderToast,          w:320, h:176 },
];

// ── MAIN ─────────────────────────────────────────────────────────

(async () => {
  for (const style of Object.values(W)) {
    await figma.loadFontAsync({ family:'Inter', style });
  }

  // ── Variables ──────────────────────────────────────────────────
  const colColl = figma.variables.createVariableCollection('Colors');
  const lightId = colColl.modes[0].modeId;
  colColl.renameMode(lightId, 'Light');
  const darkId = colColl.addMode('Dark');
  for (const [name, lHex] of Object.entries(LIGHT)) {
    const v = figma.variables.createVariable(name, colColl, 'COLOR');
    v.setValueForMode(lightId, hex(lHex));
    v.setValueForMode(darkId, hex(DARK[name]));
  }

  const spcColl = figma.variables.createVariableCollection('Spacing');
  spcColl.renameMode(spcColl.modes[0].modeId, 'Default');
  for (const [name, val] of Object.entries(SPACING)) {
    const v = figma.variables.createVariable(name, spcColl, 'FLOAT');
    v.setValueForMode(spcColl.modes[0].modeId, val);
  }

  const radColl = figma.variables.createVariableCollection('Radius');
  radColl.renameMode(radColl.modes[0].modeId, 'Default');
  for (const [name, val] of Object.entries(RADIUS)) {
    const v = figma.variables.createVariable(name, radColl, 'FLOAT');
    v.setValueForMode(radColl.modes[0].modeId, val);
  }

  const motColl = figma.variables.createVariableCollection('Motion');
  motColl.renameMode(motColl.modes[0].modeId, 'Default');
  for (const [name, val] of Object.entries(MOTION)) {
    const v = figma.variables.createVariable(`${name} (ms)`, motColl, 'FLOAT');
    v.setValueForMode(motColl.modes[0].modeId, val);
  }

  // ── Local Paint Styles ─────────────────────────────────────────
  for (const [name, colorHex] of Object.entries(LIGHT)) {
    const s = figma.createPaintStyle();
    s.name = name;
    s.paints = [{ type:'SOLID', color:hex(colorHex) }];
  }

  // ── Local Text Styles ──────────────────────────────────────────
  for (const ts of TEXT_STYLES) {
    const s = figma.createTextStyle();
    s.name = ts.name;
    s.fontName = { family:'Inter', style: W[ts.weight] };
    s.fontSize = ts.size;
    s.lineHeight = { unit:'PERCENT', value: ts.lineHeight };
    if (ts.tracking !== 0) s.letterSpacing = { unit:'PIXELS', value: ts.tracking };
  }

  // ── Pages ──────────────────────────────────────────────────────
  const page = figma.createPage();
  page.name = '🎨 Design System';
  figma.currentPage = page;

  const DARK_TEXT = hex('#141627');
  const MUTED     = hex('#626577');
  const BORDER    = hex('#DDDDDD');
  const PRIMARY   = hex('#D1F366');

  let y = 0;

  // ── Colors ────────────────────────────────────────────────────
  y = sectionHeader(page, 'Colors', y);
  const SW=88, SH=56, SCOLS=5, SGAPX=16, SGAPY=36;
  let ci = 0;
  for (const [name, lightHex] of Object.entries(LIGHT)) {
    const cx2 = (ci % SCOLS) * (SW + SGAPX);
    const cy2 = y + Math.floor(ci / SCOLS) * (SH + SGAPY + 32);
    rect(page, SW, SH, cx2, cy2, hex(lightHex), { radius:8, stroke:BORDER });
    rect(page, SW/2-2, 12, cx2, cy2+SH+4, hex(DARK[name]), { radius:4 });
    text(page, name.split('/')[1], 10, 400, MUTED, cx2, cy2+SH+20);
    ci++;
  }
  y += Math.ceil(Object.keys(LIGHT).length / SCOLS) * (SH + SGAPY + 36) + 64;

  // ── Typography ────────────────────────────────────────────────
  y = sectionHeader(page, 'Typography', y);
  for (const ts of TEXT_STYLES) {
    text(page, `${ts.name}  ·  ${ts.size}px / w${ts.weight}`, 11, 400, MUTED, 0, y);
    y += 18;
    text(page, 'The quick brown fox jumps over the lazy dog', ts.size, ts.weight, DARK_TEXT, 0, y);
    y += Math.round(ts.size * (ts.lineHeight / 100)) + 12;
  }
  y += 48;

  // ── Spacing ───────────────────────────────────────────────────
  y = sectionHeader(page, 'Spacing', y);
  for (const [name, val] of Object.entries(SPACING)) {
    if (val === 0) continue;
    text(page, `${name}  ·  ${val}px`, 12, 400, MUTED, 0, y + 4);
    rect(page, val, 24, 120, y, PRIMARY, { radius:4 });
    y += 36;
  }
  y += 48;

  // ── Radius ────────────────────────────────────────────────────
  y = sectionHeader(page, 'Radius', y);
  let rx = 0;
  for (const [name, val] of Object.entries(RADIUS)) {
    if (val === 9999) {
      rect(page, 120, 40, rx, y+20, hex('#FFFFFF'), { radius:9999, stroke:BORDER });
      text(page, `${name} · pill`, 11, 400, MUTED, rx, y+68);
      rx += 152;
      continue;
    }
    rect(page, 80, 80, rx, y, hex('#FFFFFF'), { radius:val, stroke:BORDER });
    text(page, `${name}\n${val}px`, 11, 400, MUTED, rx, y+88);
    rx += 112;
  }
  y += 80 + 56 + 48;

  // ── Components ────────────────────────────────────────────────
  y = sectionHeader(page, 'Components', y);

  const COL_MAX_W = 560;
  let compX = 0;
  let compY = y;
  let rowH = 0;

  for (const comp of CATALOGUE) {
    const cardH = comp.h + 56; // 44px header + 12px bottom padding

    // Wrap to next row if doesn't fit
    if (compX > 0 && compX + comp.w + 24 > 1200) {
      compX = 0;
      compY += rowH + 24;
      rowH = 0;
    }

    // Draw card background
    const card = frame(page, comp.w + 48, cardH + 24, compX, compY, hex('#FFFFFF'), { radius:16, stroke:BORDER });

    // Card header
    rect(card, comp.w + 48, 44, 0, 0, hex('#F8F8F8'));
    text(card, comp.name, 13, 600, DARK_TEXT, 16, 14);
    text(card, comp.subtitle, 10, 400, MUTED, 16, 30);

    // Render the component visually
    comp.render(card, 24, 56);

    rowH = Math.max(rowH, cardH + 24);
    compX += comp.w + 48 + 24;
  }

  figma.viewport.scrollAndZoomIntoView(page.children);
  figma.closePlugin('✅ DJTilbud Design System created with visual components!');
})();
