/**
 * Fresh green skin for the DSH web UI — a small theme studio.
 *
 *  - wallpaper: a bundled 4K photo, your own image, or a looping video;
 *  - transparency slider with an adaptive ("auto") mode derived from how bright
 *    the wallpaper is, so text stays readable on any picture;
 *  - palette: keep the green theme, derive one from the wallpaper, or pick the
 *    accent / sidebar / bubble / text colours yourself;
 *  - font picker, and named themes you can save and recall with Ctrl+Alt+<1..9>.
 *
 * Tokens go through the Client `theme` service (overrideTokens keeps
 * light/dark/system switching intact); the wallpaper and the per-area colours
 * are plain CSS variables so changes apply instantly.
 *
 * Preferences: a JSON blob in localStorage (images as data URIs) plus the video
 * blob in IndexedDB. Presets are inlined by tools/build-client.py.
 */

const SOURCE = 'dsh-fresh-green-skin'
const STATE_KEY = 'fresh-green-skin:state'
const THEMES_KEY = 'fresh-green-skin:themes'
const LEGACY_IMAGE_KEY = 'fresh-green-skin:wallpaper'
const LEGACY_VEIL_KEY = 'fresh-green-skin:veil'
const VIDEO_DB = 'fresh-green-skin'
const VIDEO_STORE = 'media'
const VIDEO_KEY = 'video'

const DEFAULT_VEIL = 0.34
const MAX_IMAGE_EDGE = 1920

/** Injected by tools/build-client.py: [{ id, label, value }]. */
const PRESETS = __PRESETS__

const FONTS = [
  { id: '', label: '默认（跟随 DSH）' },
  { id: '"Microsoft YaHei", "PingFang SC", "Noto Sans SC", sans-serif', label: '黑体' },
  { id: '"Source Han Serif SC", "Songti SC", SimSun, serif', label: '宋体' },
  { id: '"LXGW WenKai", KaiTi, "Kaiti SC", serif', label: '楷体' },
  { id: 'Georgia, "Times New Roman", serif', label: '衬线（英文）' },
  { id: '"Cascadia Code", Consolas, "Courier New", monospace', label: '等宽' },
]

const BASE_TOKENS = {
  '--dsw-alias-bg-base': { light: 'rgba(255,255,255,0)', dark: 'rgba(0,0,0,0)' },
  '--dsw-specific-sidebar-fill': { light: 'rgba(0,0,0,0)', dark: 'rgba(0,0,0,0)' },
  '--dsw-alias-bg-layer-1': { light: 'rgba(255,255,255,0.72)', dark: 'rgba(18,30,23,0.82)' },
  '--dsw-alias-bg-layer-2': { light: 'rgba(255,255,255,0.84)', dark: 'rgba(24,38,30,0.88)' },
  '--dsw-alias-bg-layer-3': { light: 'rgba(255,255,255,0.92)', dark: 'rgba(30,46,37,0.93)' },
  '--dsw-alias-bg-overlay': { light: '#ffffff', dark: '#16241c' },
  '--dsw-alias-border-l1': { light: 'rgba(47,143,91,0.16)', dark: 'rgba(140,220,175,0.14)' },
  '--dsw-alias-border-l2': { light: 'rgba(47,143,91,0.22)', dark: 'rgba(140,220,175,0.20)' },
  '--dsw-alias-border-l3': { light: 'rgba(47,143,91,0.30)', dark: 'rgba(140,220,175,0.28)' },
  '--dsw-alias-brand-primary': { light: '#2e8b57', dark: '#7ed7a6' },
  '--dsw-alias-state-business-primary': { light: '#2e8b57', dark: '#7ed7a6' },
  '--dsw-alias-state-success-primary': { light: '#2e8b57', dark: '#6fcf97' },
  '--dsw-alias-label-primary': { light: '#0f1c14', dark: '#eaf5ee' },
  '--dsw-alias-label-secondary': { light: '#3d5346', dark: '#c2d8c9' },
  '--dsw-alias-label-tertiary': { light: '#63806f', dark: '#93ab9c' },
}

const CSS = `
body[data-fresh-skin='on'] {
  background-color: #eef6f0 !important;
  background-image:
    linear-gradient(rgba(255,255,255,var(--fgw-veil,${DEFAULT_VEIL})), rgba(255,255,255,var(--fgw-veil,${DEFAULT_VEIL}))),
    var(--fgw-image, none) !important;
  background-size: auto, cover !important;
  background-position: center center, center center !important;
  background-repeat: no-repeat, no-repeat !important;
  background-attachment: fixed, fixed !important;
  font-family: var(--fgw-font, inherit);
}
body[data-fresh-skin='on'][data-fgw-video='on'] {
  background-image: none !important;
  /* The video and its veil are fixed elements at negative z-index: the body
     itself must stay transparent, the colour goes on <html>. */
  background-color: transparent !important;
}
body[data-ds-dark-theme][data-fresh-skin='on'] {
  background-image:
    linear-gradient(rgba(6,12,9,var(--fgw-veil-dark,0.60)), rgba(6,12,9,var(--fgw-veil-dark,0.60))),
    var(--fgw-image, none) !important;
}
/* Video wallpaper sits behind everything; the veil is a sibling overlay. */
.fgw-video { position: fixed; inset: 0; width: 100%; height: 100%; object-fit: cover; z-index: -2; pointer-events: none; }
.fgw-video-veil {
  position: fixed; inset: 0; z-index: -1; pointer-events: none;
  background: rgba(255,255,255,var(--fgw-veil,${DEFAULT_VEIL}));
}
body[data-ds-dark-theme] .fgw-video-veil { background: rgba(6,12,9,var(--fgw-veil-dark,0.60)); }
/* The frame token is transparent so the wallpaper shows; the sidebar keeps its
   own frosted panel so navigation text stays readable. */
body[data-fresh-skin='on'] [class*='_sidebarCol'] { background: var(--fgw-sidebar, rgba(250,253,250,0.62)) !important; }
body[data-ds-dark-theme][data-fresh-skin='on'] [class*='_sidebarCol'] { background: var(--fgw-sidebar, rgba(13,24,18,0.80)) !important; }
/* Windows paints the titlebar strip from the sidebar fill, so the same tint keeps
   the top bar and the sidebar reading as one surface instead of two panels. */
body[data-fresh-skin='on'] [class*='_frame']::before { background: var(--fgw-sidebar, rgba(250,253,250,0.62)) !important; }
body[data-ds-dark-theme][data-fresh-skin='on'] [class*='_frame']::before { background: var(--fgw-sidebar, rgba(13,24,18,0.80)) !important; }
/* Brand marks: the home pixel whale is a canvas painted from its computed
   colour, the sidebar lockup is inline SVG — both follow the theme variables. */
body[data-fresh-skin='on'] canvas[data-home-whale] {
  filter: none !important;
  color: var(--fgw-whale, var(--dsw-alias-label-secondary)) !important;
}
body[data-fresh-skin='on'] [class*='_fish'] svg,
body[data-fresh-skin='on'] [class*='_fish'] path {
  fill: var(--fgw-whale, currentColor) !important;
}
/* Optional: tint the sidebar wordmark. Off by default — the lockup also carries
   the HARNESS badge, which would be painted with the same colour and vanish. */
body[data-fgw-brand-tint='on'] [class*='_brandName'],
body[data-fgw-brand-tint='on'] [class*='_brandIdentity'],
body[data-fgw-brand-tint='on'] [class*='_titleGroup'] {
  color: var(--fgw-brandtext, inherit) !important;
}
/* Quick-launch chips docked right above the composer. */
.fgw-dock {
  display: flex; align-items: center; flex-wrap: wrap; gap: 8px;
  padding: 8px 4px 6px; font-size: 12px; color: var(--dsw-alias-label-secondary);
}
.fgw-dock-chip {
  display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px 4px 4px;
  border-radius: 999px; cursor: pointer; font: inherit; font-size: 12px; line-height: 18px;
  color: var(--dsw-alias-label-primary);
  background: var(--dsw-alias-bg-layer-2);
  border: 1px solid var(--dsw-alias-border-l2);
  backdrop-filter: blur(6px);
}
.fgw-dock-chip:hover { border-color: var(--dsw-alias-brand-primary); }
.fgw-dock-mark {
  width: 20px; height: 20px; border-radius: 50%; flex: none;
  display: inline-flex; align-items: center; justify-content: center;
  color: #fff; font-size: 11px; font-weight: 600; line-height: 1;
}
.fgw-picker { position: fixed; inset: 0; z-index: 9999; background: rgba(8,16,12,.72); display: flex; align-items: center; justify-content: center; cursor: crosshair; }
.fgw-picker img { max-width: 88vw; max-height: 88vh; display: block; box-shadow: 0 20px 60px rgba(0,0,0,.5); border-radius: 12px; }
.fgw-row { padding: 16px 0; border-bottom: .5px solid var(--dsw-alias-border-l2); color: var(--dsw-alias-label-primary); }
.fgw-line { display: flex; align-items: center; gap: 16px; }
.fgw-line + .fgw-line { margin-top: 10px; }
.fgw-stack { flex-direction: column; align-items: stretch; gap: 8px; }
.fgw-chiprow { display: flex; align-items: center; gap: 8px; }
.fgw-chiprow .fgw-label { width: auto; }
.fgw-label { width: 48px; flex: none; font-size: 13px; }
.fgw-gallery { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.fgw-chip {
  width: 64px; height: 40px; padding: 0; flex: none; cursor: pointer; position: relative; overflow: hidden;
  border-radius: 8px; border: 2px solid transparent;
  background-size: cover; background-position: center; background-repeat: no-repeat;
  box-shadow: inset 0 0 0 1px var(--dsw-alias-border-l2);
  color: var(--dsw-alias-label-secondary); font-size: 11px;
}
.fgw-chip.active { border-color: var(--dsw-alias-brand-primary); box-shadow: 0 0 0 2px rgba(46,139,87,.20); }
.fgw-chip.video { display: flex; align-items: center; justify-content: center; background: var(--dsw-alias-bg-layer-2); }
.fgw-main { flex: 1; min-width: 0; }
.fgw-title { font-size: 14px; line-height: 20px; }
.fgw-actions { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
.fgw-inline { padding-left: 0; }
.fgw-btn {
  font: inherit; font-size: 12px; line-height: 18px; padding: 5px 12px; border-radius: 8px;
  cursor: pointer; color: var(--dsw-alias-label-primary);
  background: var(--dsw-alias-bg-layer-3); border: 1px solid var(--dsw-alias-border-l2);
}
.fgw-btn.primary { color: #fff; border-color: transparent; background: var(--dsw-alias-brand-primary); }
.fgw-btn:disabled { opacity: .55; cursor: default; }
.fgw-slider { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; }
.fgw-slider input[type='range'] { flex: 1; max-width: 220px; accent-color: var(--dsw-alias-brand-primary); }
.fgw-value { font-size: 12px; color: var(--dsw-alias-label-secondary); min-width: 44px; }
.fgw-toggle { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; color: var(--dsw-alias-label-secondary); cursor: pointer; }
.fgw-swatch {
  width: 26px; height: 26px; padding: 0; border-radius: 6px; cursor: pointer;
  border: 1px solid var(--dsw-alias-border-l2); background: transparent;
}
.fgw-swatch:disabled { opacity: .45; cursor: default; }
.fgw-select, .fgw-input {
  font: inherit; font-size: 12px; padding: 4px 8px; border-radius: 8px;
  color: var(--dsw-alias-label-primary); background: var(--dsw-alias-bg-layer-3);
  border: 1px solid var(--dsw-alias-border-l2);
}
.fgw-input { width: 132px; }
.fgw-note { font-size: 12px; color: var(--dsw-alias-brand-primary); margin-top: 8px; }
.fgw-hint { font-size: 11px; color: var(--dsw-alias-label-tertiary); }
`

// ---------------------------------------------------------------- helpers ---

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value))
}

function hslToRgb(h, s, l) {
  const c = (1 - Math.abs(2 * l - 1)) * s
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1))
  const m = l - c / 2
  const table = [
    [c, x, 0],
    [x, c, 0],
    [0, c, x],
    [0, x, c],
    [x, 0, c],
    [c, 0, x],
  ][Math.floor(h / 60) % 6]
  const [r, g, b] = table.map((channel) => Math.round((channel + m) * 255))
  return `rgb(${r}, ${g}, ${b})`
}

function rgbToHsl(r, g, b) {
  const max = Math.max(r, g, b)
  const min = Math.min(r, g, b)
  const l = (max + min) / 2 / 255
  const delta = max - min
  if (delta === 0) return { h: 0, s: 0, l }
  const s = delta / 255 / (1 - Math.abs(2 * l - 1))
  let h
  if (max === r) h = 60 * (((g - b) / delta) % 6)
  else if (max === g) h = 60 * ((b - r) / delta + 2)
  else h = 60 * ((r - g) / delta + 4)
  return { h: (h + 360) % 360, s, l }
}

/** '#2e8b57' + 0.62 -> 'rgba(46,139,87,0.62)'; leaves non-hex input untouched. */
function withAlpha(color, alpha) {
  const value = String(color || '').trim()
  const ratio = clamp(Number(alpha) / 100, 0, 1)
  const hex = value.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i)
  if (!hex) return value
  let digits = hex[1]
  if (digits.length === 3) digits = digits.split('').map((ch) => ch + ch).join('')
  const r = parseInt(digits.slice(0, 2), 16)
  const g = parseInt(digits.slice(2, 4), 16)
  const b = parseInt(digits.slice(4, 6), 16)
  return `rgba(${r},${g},${b},${ratio})`
}

/** Pick readable text for the current wallpaper: dark on a light photo, light on
    a dark one, so the "follow the system" palette never ends up unreadable. */
function contrastText(darkMode) {
  if (darkMode) return '#eef7f1'
  const sample = runtime.derived && runtime.derived.sample
  const luminance = sample ? Number(sample.luminance ?? sample.l ?? 0.82) : 0.82
  return luminance > 0.52 ? '#0f1c14' : '#f4fbf6'
}

/** Palette for the quick-launch chips: derived from the wallpaper when possible. */
function chipColor(item, index) {
  if (item && item.color) return item.color
  const sample = runtime.derived
  if (sample) {
    const hue = (sample.sample ? sample.sample.h : 145) + index * 47
    return hslToRgb(((hue % 360) + 360) % 360, 0.52, 0.42)
  }
  return hslToRgb((145 + index * 47) % 360, 0.52, 0.42)
}

/** Insert text into the composer (the host exposes a textarea). */
function insertIntoComposer(text) {
  const target =
    document.querySelector('[data-composer] textarea') ||
    document.querySelector('textarea[placeholder]') ||
    document.querySelector('textarea') ||
    document.querySelector('[contenteditable="true"]')
  if (!target) return false
  try {
    target.focus()
    if (typeof target.setRangeText === 'function') {
      const start = target.selectionStart === null || target.selectionStart === undefined
        ? target.value.length
        : target.selectionStart
      const end = target.selectionEnd === null || target.selectionEnd === undefined ? start : target.selectionEnd
      target.setRangeText(text, start, end, 'end')
    } else if (document.execCommand) {
      document.execCommand('insertText', false, text)
    } else {
      return false
    }
    target.dispatchEvent(new Event('input', { bubbles: true }))
    return true
  } catch {
    return false
  }
}

/** Average colour + brightness of an image URL or a <video>/<img> element. */
function analyzePixels(source) {
  return new Promise((resolve) => {
    try {
      const canvas = document.createElement('canvas')
      canvas.width = 24
      canvas.height = 16
      const context = canvas.getContext('2d')
      if (!context) return resolve(null)
      context.drawImage(source, 0, 0, canvas.width, canvas.height)
      const data = context.getImageData(0, 0, canvas.width, canvas.height).data
      let r = 0
      let g = 0
      let b = 0
      let count = 0
      for (let index = 0; index < data.length; index += 4) {
        const alpha = data[index + 3]
        if (alpha < 8) continue
        r += data[index]
        g += data[index + 1]
        b += data[index + 2]
        count += 1
      }
      if (!count) return resolve(null)
      r /= count
      g /= count
      b /= count
      const hsl = rgbToHsl(r, g, b)
      resolve({
        h: hsl.h,
        s: hsl.s,
        l: hsl.l,
        luminance: (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255,
      })
    } catch {
      resolve(null)
    }
  })
}

function paletteFromSample(sample) {
  if (!sample) return null
  const h = sample.h
  // Keep a green-leaning but wallpaper-derived accent: nudge the hue towards
  // 145° (leaf green) when the wallpaper is nearly neutral.
  const hue = sample.s < 0.08 ? 145 : h
  return {
    brand: hslToRgb(hue, clamp(sample.s + 0.18, 0.42, 0.72), clamp(0.42 - sample.l * 0.1, 0.3, 0.46)),
    brandDark: hslToRgb(hue, clamp(sample.s + 0.1, 0.35, 0.6), 0.72),
    sidebar: `rgba(255,255,255,${clamp(0.72 - sample.l * 0.25, 0.45, 0.72)})`,
    bubble: `rgba(255,255,255,${clamp(0.9 - sample.l * 0.2, 0.72, 0.92)})`,
    text: hslToRgb(hue, 0.35, 0.12),
    veil: clamp(0.7 - sample.luminance * 0.55, 0.26, 0.74),
    sample,
  }
}

// --------------------------------------------------------------- storage ---

function openVideoDb() {
  return new Promise((resolve, reject) => {
    if (typeof indexedDB === 'undefined') return reject(new Error('浏览器不支持 IndexedDB'))
    const request = indexedDB.open(VIDEO_DB, 1)
    request.onupgradeneeded = () => {
      const db = request.result
      if (!db.objectStoreNames.contains(VIDEO_STORE)) db.createObjectStore(VIDEO_STORE)
    }
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error || new Error('打开 IndexedDB 失败'))
  })
}

async function saveVideo(blob, name) {
  const db = await openVideoDb()
  await new Promise((resolve, reject) => {
    const tx = db.transaction(VIDEO_STORE, 'readwrite')
    tx.objectStore(VIDEO_STORE).put({ blob, name }, VIDEO_KEY)
    tx.oncomplete = () => resolve()
    tx.onerror = () => reject(tx.error || new Error('保存视频失败'))
  })
  db.close()
}

async function loadVideo() {
  if (typeof indexedDB === 'undefined') return null
  try {
    const db = await openVideoDb()
    const entry = await new Promise((resolve, reject) => {
      const tx = db.transaction(VIDEO_STORE, 'readonly')
      const request = tx.objectStore(VIDEO_STORE).get(VIDEO_KEY)
      request.onsuccess = () => resolve(request.result || null)
      request.onerror = () => reject(request.error)
    })
    db.close()
    return entry
  } catch {
    return null
  }
}

async function clearVideo() {
  if (typeof indexedDB === 'undefined') return
  try {
    const db = await openVideoDb()
    await new Promise((resolve) => {
      const tx = db.transaction(VIDEO_STORE, 'readwrite')
      tx.objectStore(VIDEO_STORE).delete(VIDEO_KEY)
      tx.oncomplete = () => resolve()
      tx.onerror = () => resolve()
    })
    db.close()
  } catch {
    /* ignore */
  }
}

// ----------------------------------------------------------------- state ---

const listeners = new Set()
const runtime = { video: null, videoUrl: null, veilCss: null, tokens: null }
let state = null
let hostCtx = null
let disposeTokens = null

function defaults() {
  return {
    source: { kind: 'preset', id: PRESETS[0].id },
    veil: DEFAULT_VEIL,
    autoVeil: false,
    palette: 'theme',
    brandTint: false,
    colors: { brand: '', sidebar: '', bubble: '', text: '', whale: '', wordmark: '' },
    alpha: { sidebar: 62, bubble: 88 },
    chips: { enabled: true, items: [] },
    font: '',
  }
}

function readState() {
  const fallback = defaults()
  try {
    const raw = localStorage.getItem(STATE_KEY)
    if (raw) {
      const parsed = JSON.parse(raw)
      return {
        ...fallback,
        ...parsed,
        colors: { ...fallback.colors, ...(parsed.colors || {}) },
        alpha: { ...fallback.alpha, ...(parsed.alpha || {}) },
        chips: { ...fallback.chips, ...(parsed.chips || {}) },
      }
    }
    // Migrate the flat keys written by 1.3.x.
    const legacy = localStorage.getItem(LEGACY_IMAGE_KEY)
    const legacyVeil = localStorage.getItem(LEGACY_VEIL_KEY)
    const migrated = { ...fallback }
    if (legacy && legacy.startsWith('preset:')) {
      migrated.source = { kind: 'preset', id: legacy.slice('preset:'.length) }
    } else if (legacy && legacy.startsWith('custom:')) {
      migrated.source = { kind: 'image', src: legacy.slice('custom:'.length) }
    } else if (legacy) {
      migrated.source = { kind: 'image', src: /^(url|data:image)/.test(legacy) ? legacy : '' }
    }
    if (legacyVeil !== null && Number.isFinite(Number(legacyVeil))) migrated.veil = Number(legacyVeil)
    return migrated
  } catch {
    return fallback
  }
}

function getState() {
  if (!state) state = readState()
  return state
}

function backgroundCss(next) {
  if (next.source.kind === 'preset') {
    const preset = PRESETS.find((item) => item.id === next.source.id) || PRESETS[0]
    return preset.value
  }
  if (next.source.kind === 'image' && next.source.src) {
    const raw = next.source.src
    return /^(url|data:image)/.test(raw) ? (raw.startsWith('url(') ? raw : `url("${raw}")`) : 'none'
  }
  return 'none'
}

function resolveVeil(next) {
  if (next.autoVeil && runtime.derived) return clamp(Number(runtime.derived.veil), 0.15, 0.85)
  const raw = Number(next.veil)
  return clamp(Number.isFinite(raw) ? raw : DEFAULT_VEIL, 0, 1)
}

function buildTokens(next) {
  const tokens = JSON.parse(JSON.stringify(BASE_TOKENS))
  const sample = next.palette === 'image' ? runtime.derived : null
  const colors = next.colors || {}
  const alpha = next.alpha || {}

  if (next.palette === 'system') {
    // Follow whatever the host theme is: neutral frosted surfaces over the
    // wallpaper and a text colour picked for contrast, no colour cast of ours.
    tokens['--dsw-alias-bg-layer-1'] = { light: 'rgba(255,255,255,0.60)', dark: 'rgba(18,24,20,0.66)' }
    tokens['--dsw-alias-bg-layer-2'] = { light: 'rgba(255,255,255,0.78)', dark: 'rgba(22,30,25,0.80)' }
    tokens['--dsw-alias-bg-layer-3'] = { light: 'rgba(255,255,255,0.90)', dark: 'rgba(28,38,32,0.90)' }
    tokens['--dsw-alias-label-primary'] = { light: contrastText(false), dark: '#eef7f1' }
  }

  if (sample) {
    tokens['--dsw-alias-brand-primary'] = { light: sample.brand, dark: sample.brandDark }
    tokens['--dsw-alias-state-business-primary'] = { light: sample.brand, dark: sample.brandDark }
    tokens['--dsw-alias-state-success-primary'] = { light: sample.brand, dark: sample.brandDark }
    tokens['--dsw-alias-label-primary'] = { light: sample.text, dark: '#eaf5ee' }
    tokens['--dsw-alias-bg-layer-2'] = { light: sample.bubble, dark: 'rgba(24,38,30,0.88)' }
    tokens['--dsw-alias-bg-layer-3'] = { light: sample.bubble, dark: 'rgba(30,46,37,0.93)' }
  }

  if (colors.brand) {
    tokens['--dsw-alias-brand-primary'] = { light: colors.brand, dark: colors.brand }
    tokens['--dsw-alias-state-business-primary'] = { light: colors.brand, dark: colors.brand }
  }
  if (colors.bubble) {
    // Bubbles keep the wallpaper visible: the colour is a tint with its own
    // opacity, not a solid fill.
    const translucent = withAlpha(colors.bubble, alpha.bubble)
    const dark = withAlpha(colors.bubble, clamp(Number(alpha.bubble) + 8, 0, 100))
    tokens['--dsw-alias-bg-layer-2'] = { light: translucent, dark }
    tokens['--dsw-alias-bg-layer-3'] = { light: translucent, dark }
  }
  if (colors.text) {
    tokens['--dsw-alias-label-primary'] = { light: colors.text, dark: colors.text }
  }
  return tokens
}

function applyTokens(next) {
  if (!hostCtx || !hostCtx.theme || typeof hostCtx.theme.overrideTokens !== 'function') return
  try {
    if (disposeTokens) disposeTokens()
    disposeTokens = hostCtx.theme.overrideTokens(SOURCE, buildTokens(next))
  } catch {
    /* theme service unavailable: colours simply stay at the last value */
  }
}

function applyState(next) {
  const root = document.documentElement
  const veil = resolveVeil(next)
  root.style.setProperty('--fgw-veil', String(veil))
  root.style.setProperty('--fgw-veil-dark', String(veil))
  root.style.setProperty('--fgw-image', backgroundCss(next))
  root.style.setProperty('--fgw-font', next.font || 'inherit')

  const colors = next.colors || {}
  const alpha = next.alpha || {}
  const sidebar = colors.sidebar
  if (sidebar) root.style.setProperty('--fgw-sidebar', withAlpha(sidebar, alpha.sidebar))
  else root.style.removeProperty('--fgw-sidebar')

  if (colors.whale) root.style.setProperty('--fgw-whale', colors.whale)
  else root.style.removeProperty('--fgw-whale')
  if (next.brandTint && colors.wordmark) root.style.setProperty('--fgw-brandtext', colors.wordmark)
  else root.style.removeProperty('--fgw-brandtext')

  const body = document.body
  if (body) {
    body.dataset.freshSkin = 'on'
    if (next.brandTint && colors.wordmark) body.dataset.fgwBrandTint = 'on'
    else delete body.dataset.fgwBrandTint
    if (next.source.kind === 'video') body.dataset.fgwVideo = 'on'
    else delete body.dataset.fgwVideo
  }

  applyTokens(next)
  syncVideo(next)
}

function syncVideo(next) {
  const wantsVideo = next.source.kind === 'video' && runtime.videoUrl
  const root = document.documentElement
  let video = runtime.video
  if (!wantsVideo) {
    if (video) video.style.display = 'none'
    if (runtime.veilCss) runtime.veilCss.style.display = 'none'
    root.style.removeProperty('background-color')
    return
  }
  root.style.backgroundColor = '#08120c'
  if (!video) {
    video = document.createElement('video')
    video.className = 'fgw-video'
    video.muted = true
    video.loop = true
    video.autoplay = true
    video.playsInline = true
    video.setAttribute('playsinline', '')
    runtime.video = video
    document.body.appendChild(video)
  }
  if (!runtime.veilCss) {
    runtime.veilCss = document.createElement('div')
    runtime.veilCss.className = 'fgw-video-veil'
    document.body.appendChild(runtime.veilCss)
  }
  video.style.display = ''
  runtime.veilCss.style.display = ''
  if (video.src !== runtime.videoUrl) video.src = runtime.videoUrl
  const started = video.play()
  if (started && typeof started.catch === 'function') started.catch(() => {})
}

function persist(next) {
  try {
    const copy = {
      source: next.source.kind === 'video' ? { kind: 'video', name: next.source.name || 'video' } : next.source,
      veil: next.veil,
      autoVeil: next.autoVeil,
      palette: next.palette,
      colors: next.colors,
      font: next.font,
    }
    if (copy.source.kind === 'image' && copy.source.src && copy.source.src.length > 4 * 1024 * 1024) {
      throw new Error('图片太大，无法保存')
    }
    localStorage.setItem(STATE_KEY, JSON.stringify(copy))
    return null
  } catch (error) {
    return error instanceof Error ? error.message : String(error)
  }
}

function setState(next) {
  state = next
  applyState(next)
  const failure = persist(next)
  for (const listener of listeners) listener(next, failure)
  return failure
}

// ---------------------------------------------------------------- media ---

function readImageFile(file, done) {
  const reader = new FileReader()
  reader.onerror = () => done(new Error('读取文件失败'))
  reader.onload = () => {
    const image = new Image()
    image.onerror = () => done(new Error('这张图片无法解析'))
    image.onload = () => {
      const scale = Math.min(1, MAX_IMAGE_EDGE / image.naturalWidth)
      const canvas = document.createElement('canvas')
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale))
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale))
      const context = canvas.getContext('2d')
      if (!context) return done(new Error('浏览器不支持 canvas'))
      context.drawImage(image, 0, 0, canvas.width, canvas.height)
      done(null, canvas.toDataURL('image/jpeg', 0.9))
    }
    image.src = String(reader.result)
  }
  reader.readAsDataURL(file)
}

function sampleSource(next) {
  const bg = backgroundCss(next)
  if (next.source.kind === 'video' && runtime.video) {
    const video = runtime.video
    const measure = () => {
      analyzePixels(video).then((sample) => {
        runtime.sample = sample
        runtime.derived = paletteFromSample(sample)
        if (state && (state.autoVeil || state.palette === 'image' || state.palette === 'system')) applyState(state)
      })
    }
    // Drawing a video before it has a frame yields black, so wait for data.
    if (video.readyState >= 2) measure()
    else video.addEventListener('loadeddata', measure, { once: true })
    return
  }
  const url = bg.match(/url\("?([^")]+)"?\)/)
  if (!url) {
    runtime.sample = null
    runtime.derived = null
    return
  }
  const image = new Image()
  image.onload = () => {
    analyzePixels(image).then((sample) => {
      runtime.sample = sample
      runtime.derived = paletteFromSample(sample)
      if (state && (state.autoVeil || state.palette === 'image' || state.palette === 'system')) applyState(state)
    })
  }
  image.src = url[1]
}

// ------------------------------------------------------------------ host ---

function mountDom() {
  const style = document.createElement('style')
  style.dataset.freshGreenSkin = 'on'
  style.textContent = CSS
  document.head.appendChild(style)

  loadVideo().then((entry) => {
    if (entry && entry.blob) {
      runtime.videoUrl = URL.createObjectURL(entry.blob)
      runtime.videoName = entry.name
      const current = getState()
      if (current.source.kind === 'video') applyState(current)
      for (const listener of listeners) listener(current, null)
    }
  })

  const current = getState()
  applyState(current)
  sampleSource(current)

  return () => {
    style.remove()
    if (runtime.video) runtime.video.remove()
    if (runtime.veilCss) runtime.veilCss.remove()
    if (runtime.videoUrl) URL.revokeObjectURL(runtime.videoUrl)
    runtime.video = null
    runtime.veilCss = null
    runtime.videoUrl = null
    if (document.body) delete document.body.dataset.freshSkin
  }
}

function readThemes() {
  try {
    const parsed = JSON.parse(localStorage.getItem(THEMES_KEY) || '[]')
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}

function writeThemes(themes) {
  try {
    localStorage.setItem(THEMES_KEY, JSON.stringify(themes))
  } catch {
    /* ignore */
  }
}

// ------------------------------------------------------------- picking ----

/** Click the wallpaper to take its colour. Resolves with '#rrggbb' or null. */
function pickColorFromWallpaper(next, done) {
  const url = backgroundCss(next).match(/url\("?([^")]+)"?\)/)
  if (!url) {
    done(null)
    return
  }
  const overlay = document.createElement('div')
  overlay.className = 'fgw-picker'
  overlay.title = '点一下取这里的颜色'
  const image = document.createElement('img')
  image.src = url[1]
  image.alt = '壁纸'
  overlay.appendChild(image)
  overlay.addEventListener('click', (event) => {
    try {
      const rect = image.getBoundingClientRect()
      const x = Math.round(((event.clientX - rect.left) / rect.width) * image.naturalWidth)
      const y = Math.round(((event.clientY - rect.top) / rect.height) * image.naturalHeight)
      const canvas = document.createElement('canvas')
      canvas.width = 1
      canvas.height = 1
      const context = canvas.getContext('2d')
      context.drawImage(image, x, y, 1, 1, 0, 0, 1, 1)
      const [r, g, b] = context.getImageData(0, 0, 1, 1).data
      done(`#${[r, g, b].map((channel) => channel.toString(16).padStart(2, '0')).join('')}`)
    } catch {
      done(null)
    }
    overlay.remove()
  })
  document.body.appendChild(overlay)
}

function installShortcuts() {
  const onKey = (event) => {
    if (!event.ctrlKey || !event.altKey || event.shiftKey) return
    if (!/^[0-9]$/.test(event.key)) return
    const index = Number(event.key)
    event.preventDefault()
    if (index === 0) {
      setState({ ...defaults() })
      return
    }
    const theme = readThemes()[index - 1]
    if (theme && theme.value) setState({ ...defaults(), ...theme.value })
  }
  window.addEventListener('keydown', onKey)
  return () => window.removeEventListener('keydown', onKey)
}

// ------------------------------------------------------------ settings ----

window.__ModuleLoader__.load({
  id: 'dsh-fresh-green-skin',
  factory(require) {
    const h = require('react').createElement
    const { useState, useEffect, useRef } = require('react')

    function ThemeRow() {
      const [current, setCurrent] = useState(getState)
      const [note, setNote] = useState('')
      const [themes, setThemes] = useState(readThemes)
      const [draftName, setDraftName] = useState('')
      const imageRef = useRef(null)
      const videoRef = useRef(null)

      useEffect(() => {
        const listener = (next, failure) => {
          setCurrent({ ...next })
          if (failure) setNote(`保存失败：${failure}`)
        }
        listeners.add(listener)
        return () => listeners.delete(listener)
      }, [])

      const veil = Math.round(resolveVeil(current) * 100)

      const pickPreset = (preset) => {
        setNote('')
        setState({ ...current, source: { kind: 'preset', id: preset.id } })
        sampleSource({ ...current, source: { kind: 'preset', id: preset.id } })
      }

      const pickImage = () => imageRef.current && imageRef.current.click()
      const pickVideo = () => videoRef.current && videoRef.current.click()

      const onImage = (event) => {
        const file = event.target.files && event.target.files[0]
        event.target.value = ''
        if (!file) return
        setNote('正在处理图片…')
        readImageFile(file, (error, value) => {
          if (error || !value) {
            setNote(`换图失败：${error ? error.message : '未知错误'}`)
            return
          }
          const next = { ...current, source: { kind: 'image', src: value } }
          const failure = setState(next)
          sampleSource(next)
          setNote(failure ? `换图失败：${failure}` : '壁纸已更换')
        })
      }

      const onVideo = async (event) => {
        const file = event.target.files && event.target.files[0]
        event.target.value = ''
        if (!file) return
        setNote('正在保存视频…')
        try {
          await saveVideo(file, file.name)
          if (runtime.videoUrl) URL.revokeObjectURL(runtime.videoUrl)
          runtime.videoUrl = URL.createObjectURL(file)
          runtime.videoName = file.name
          const next = { ...current, source: { kind: 'video', name: file.name } }
          setState(next)
          sampleSource(next)
          setNote('已换成动态壁纸（无声循环播放）')
        } catch (error) {
          setNote(`视频保存失败：${error instanceof Error ? error.message : error}`)
        }
      }

      const reset = () => {
        const failure = setState(defaults())
        setNote(failure ? `恢复失败：${failure}` : '已恢复默认主题')
      }

      const saveTheme = () => {
        const name = draftName.trim()
        if (!name) {
          setNote('先给主题起个名字')
          return
        }
        const value = {
          source: current.source,
          veil: current.veil,
          autoVeil: current.autoVeil,
          palette: current.palette,
          colors: current.colors,
          alpha: current.alpha,
          chips: current.chips,
          font: current.font,
        }
        const next = [...themes.filter((item) => item.name !== name), { name, value }]
        writeThemes(next)
        setThemes(next)
        setDraftName('')
        setNote(`已保存主题「${name}」（Ctrl+Alt+${next.length} 切换）`)
      }

      const applyTheme = (theme) => {
        setState({ ...defaults(), ...theme.value })
        sampleSource({ ...defaults(), ...theme.value })
        setNote(`已应用「${theme.name}」`)
      }

      const removeTheme = (theme) => {
        const next = themes.filter((item) => item.name !== theme.name)
        writeThemes(next)
        setThemes(next)
        setNote(`已删除「${theme.name}」`)
      }

      const setColors = (patch) => {
        setState({ ...current, colors: { ...current.colors, ...patch } })
      }

      const setAlpha = (patch) => {
        setState({ ...current, alpha: { ...(current.alpha || {}), ...patch } })
      }

      const pickColor = (key) => {
        pickColorFromWallpaper(current, (color) => {
          if (color) setColors({ [key]: color })
          else setNote('这张壁纸没法取色（视频壁纸请用色板）')
        })
      }

      const chipsConfig = current.chips || { enabled: true, items: [] }
      const chipItems = Array.isArray(chipsConfig.items) ? chipsConfig.items : []
      const setChips = (patch) => setState({ ...current, chips: { ...chipsConfig, ...patch } })
      const updateChip = (index, patch) =>
        setChips({ items: chipItems.map((item, position) => (position === index ? { ...item, ...patch } : item)) })
      const addChip = () =>
        setChips({ items: [...chipItems, { id: `chip-${Date.now()}`, label: '新插件', text: '', color: '' }] })
      const removeChip = (index) => setChips({ items: chipItems.filter((_, position) => position !== index) })

      const chips = PRESETS.map((preset) =>
        h('button', {
          key: preset.id,
          type: 'button',
          className: `fgw-chip${current.source.kind === 'preset' && current.source.id === preset.id ? ' active' : ''}`,
          title: preset.label,
          'aria-label': preset.label,
          style: { backgroundImage: preset.value },
          onClick: () => pickPreset(preset),
        }),
      )
      if (current.source.kind === 'image' && current.source.src) {
        chips.push(
          h('button', {
            key: 'custom',
            type: 'button',
            className: 'fgw-chip active',
            title: '我的图片',
            'aria-label': '我的图片',
            style: { backgroundImage: `url("${current.source.src}")` },
            onClick: pickImage,
          }),
        )
      }
      chips.push(
        h(
          'button',
          {
            key: 'video',
            type: 'button',
            className: `fgw-chip video${current.source.kind === 'video' ? ' active' : ''}`,
            title: current.source.kind === 'video' ? '动态壁纸（点击更换）' : '上传视频做动态壁纸',
            'aria-label': '动态壁纸',
            onClick: pickVideo,
          },
          '视频',
        ),
      )

      // Any palette can be overridden channel by channel; only "跟随壁纸" owns the
      // colours outright, so the swatches stay live everywhere else.
      const colorEnabled = current.palette !== 'image'

      return h(
        'div',
        { className: 'fgw-row' },
        h(
          'div',
          { className: 'fgw-line' },
          h('div', { className: 'fgw-title' }, '壁纸'),
          h('div', { className: 'fgw-gallery' }, chips),
          h(
            'div',
            { className: 'fgw-actions' },
            h('button', { className: 'fgw-btn primary', onClick: pickImage }, '上传图片'),
            h('button', { className: 'fgw-btn', onClick: pickVideo }, '上传视频'),
            h('button', { className: 'fgw-btn', onClick: reset }, '恢复默认'),
          ),
        ),
        h(
          'div',
          { className: 'fgw-line' },
          h('span', { className: 'fgw-label' }, '透明度'),
          h(
            'div',
            { className: 'fgw-slider' },
            h('input', {
              type: 'range',
              min: 0,
              max: 100,
              step: 1,
              value: veil,
              disabled: current.autoVeil,
              onChange: (event) => {
                const next = clamp(Number(event.target.value) / 100, 0, 1)
                setState({ ...current, veil: next, autoVeil: false })
                setNote('')
              },
            }),
            h('span', { className: 'fgw-value' }, `${veil}%`),
            h(
              'label',
              { className: 'fgw-toggle' },
              h('input', {
                type: 'checkbox',
                checked: Boolean(current.autoVeil),
                onChange: (event) => setState({ ...current, autoVeil: event.target.checked }),
              }),
              '跟随壁纸自动',
            ),
          ),
        ),
        h(
          'div',
          { className: 'fgw-line fgw-stack' },
          h(
            'div',
            { className: 'fgw-actions' },
            h('span', { className: 'fgw-label' }, '配色'),
            ...[
              ['system', '跟随系统'],
              ['theme', '默认绿'],
              ['image', '跟随壁纸'],
              ['custom', '自定义'],
            ].map(([id, label]) =>
              h(
                'button',
                {
                  key: id,
                  className: `fgw-btn${current.palette === id ? ' primary' : ''}`,
                  title:
                    id === 'system'
                      ? '用系统自带的浅/深色，只按壁纸明暗挑一个看得清的文字色'
                      : undefined,
                  onClick: () => {
                    setState({ ...current, palette: id })
                    if (id === 'image') sampleSource(current)
                  },
                },
                label,
              ),
            ),
          ),
          h(
            'div',
            { className: 'fgw-actions fgw-inline' },
            ...[
              ['brand', '主色'],
              ['sidebar', '侧栏'],
              ['bubble', '气泡'],
              ['text', '文字'],
            ].map(([key, label]) =>
              h(
                'label',
                { key, className: 'fgw-toggle', title: label },
                label,
                h('input', {
                  type: 'color',
                  className: 'fgw-swatch',
                  disabled: !colorEnabled,
                  value: current.colors[key] || '#2e8b57',
                  onChange: (event) => setColors({ [key]: event.target.value }),
                }),
                h(
                  'button',
                  {
                    type: 'button',
                    className: 'fgw-btn',
                    title: '从壁纸取色',
                    disabled: !colorEnabled,
                    onClick: () => pickColor(key),
                  },
                  '取色',
                ),
              ),
            ),
          ),
        ),
        h(
          'div',
          { className: 'fgw-line' },
          h('span', { className: 'fgw-label' }, '透光'),
          h(
            'span',
            { className: 'fgw-toggle' },
            '侧栏',
            h('input', {
              type: 'range',
              min: 0,
              max: 100,
              value: Number((current.alpha || {}).sidebar ?? 62),
              onChange: (event) => setAlpha({ sidebar: Number(event.target.value) }),
            }),
            h('span', { className: 'fgw-value' }, `${Number((current.alpha || {}).sidebar ?? 62)}%`),
          ),
          h(
            'span',
            { className: 'fgw-toggle' },
            '气泡',
            h('input', {
              type: 'range',
              min: 0,
              max: 100,
              value: Number((current.alpha || {}).bubble ?? 88),
              onChange: (event) => setAlpha({ bubble: Number(event.target.value) }),
            }),
            h('span', { className: 'fgw-value' }, `${Number((current.alpha || {}).bubble ?? 88)}%`),
          ),
          h('span', { className: 'fgw-hint' }, '越低越能看见壁纸'),
        ),
        h(
          'div',
          { className: 'fgw-line' },
          h('span', { className: 'fgw-label' }, '品牌'),
          h(
            'label',
            { className: 'fgw-toggle', title: '新会话大鲸鱼' },
            '鲸鱼',
            h('input', {
              type: 'color',
              className: 'fgw-swatch',
              value: current.colors.whale || '#2e8b57',
              onChange: (event) => setColors({ whale: event.target.value }),
            }),
          ),
          h(
            'label',
            { className: 'fgw-toggle', title: '给侧栏 deepseek HARNESS 字样着色（HARNESS 徽标会一起变色）' },
            h('input', {
              type: 'checkbox',
              checked: Boolean(current.brandTint),
              onChange: (event) => setState({ ...current, brandTint: event.target.checked }),
            }),
            '品牌字上色',
          ),
          h(
            'label',
            { className: 'fgw-toggle', title: '品牌字颜色（勾选上面才生效）' },
            h('input', {
              type: 'color',
              className: 'fgw-swatch',
              disabled: !current.brandTint,
              value: current.colors.wordmark || '#0f1c14',
              onChange: (event) => setColors({ wordmark: event.target.value }),
            }),
          ),
          h(
            'button',
            {
              type: 'button',
              className: 'fgw-btn',
              onClick: () => setState({ ...current, brandTint: false, colors: { ...current.colors, whale: '', wordmark: '' } }),
            },
            '跟随主题',
          ),
        ),
        h(
          'div',
          { className: 'fgw-line fgw-stack' },
          h(
            'div',
            { className: 'fgw-actions' },
            h('span', { className: 'fgw-label' }, '快捷条'),
            h(
              'label',
              { className: 'fgw-toggle' },
              h('input', {
                type: 'checkbox',
                checked: chipsConfig.enabled !== false,
                onChange: (event) => setChips({ enabled: event.target.checked }),
              }),
              '在输入框上方显示',
            ),
            h('button', { className: 'fgw-btn', onClick: addChip }, '添加'),
            chipItems.length
              ? null
              : h('span', { className: 'fgw-hint' }, '添加后会在新会话输入框上方以首字母图标显示，点一下插入文字'),
          ),
          chipItems.map((item, index) =>
            h(
              'div',
              { key: item.id || index, className: 'fgw-chiprow' },
              h('input', {
                className: 'fgw-input',
                style: { width: '92px' },
                value: item.label,
                placeholder: '名称',
                onChange: (event) => updateChip(index, { label: event.target.value }),
              }),
              h('input', {
                className: 'fgw-input',
                style: { flex: '1', minWidth: '120px' },
                value: item.text || '',
                placeholder: '点图标时插入的文字',
                onChange: (event) => updateChip(index, { text: event.target.value }),
              }),
              h('input', {
                type: 'color',
                className: 'fgw-swatch',
                value: item.color || chipColor(item, index),
                onChange: (event) => updateChip(index, { color: event.target.value }),
              }),
              h(
                'button',
                {
                  type: 'button',
                  className: 'fgw-btn',
                  title: '从壁纸取色',
                  onClick: () =>
                    pickColorFromWallpaper(current, (color) => {
                      if (color) updateChip(index, { color })
                    }),
                },
                '取色',
              ),
              h('button', { className: 'fgw-btn', title: '删除', onClick: () => removeChip(index) }, '×'),
            ),
          ),
        ),
        h(
          'div',
          { className: 'fgw-line' },
          h('span', { className: 'fgw-label' }, '字体'),
          h(
            'select',
            {
              className: 'fgw-select',
              value: current.font,
              onChange: (event) => setState({ ...current, font: event.target.value }),
            },
            FONTS.map((font) => h('option', { key: font.id, value: font.id }, font.label)),
          ),
          h('span', { className: 'fgw-hint' }, '只对本浏览器生效'),
        ),
        h(
          'div',
          { className: 'fgw-line' },
          h('span', { className: 'fgw-label' }, '主题'),
          h('input', {
            className: 'fgw-input',
            placeholder: '给这套配色起名',
            value: draftName,
            onChange: (event) => setDraftName(event.target.value),
          }),
          h('button', { className: 'fgw-btn primary', onClick: saveTheme }, '保存主题'),
          h(
            'div',
            { className: 'fgw-actions' },
            themes.map((theme, index) =>
              h(
                'span',
                { key: theme.name, className: 'fgw-toggle' },
                h('button', { className: 'fgw-btn', onClick: () => applyTheme(theme) }, `${theme.name}${index < 9 ? ` (⌃⌥${index + 1})` : ''}`),
                h('button', { className: 'fgw-btn', title: '删除', onClick: () => removeTheme(theme) }, '×'),
              ),
            ),
          ),
        ),
        h('input', {
          ref: imageRef,
          type: 'file',
          accept: 'image/*',
          style: { display: 'none' },
          onChange: onImage,
        }),
        h('input', {
          ref: videoRef,
          type: 'file',
          accept: 'video/*',
          style: { display: 'none' },
          onChange: onVideo,
        }),
        note ? h('div', { className: 'fgw-note' }, note) : null,
      )
    }

    ThemeRow.displayName = 'FreshGreenThemeRow'

    /** Quick-launch chips docked above the composer. */
    function ChipsDock() {
      const [current, setCurrent] = useState(getState)
      useEffect(() => {
        const listener = (next) => setCurrent({ ...next })
        listeners.add(listener)
        return () => listeners.delete(listener)
      }, [])

      const config = current.chips || {}
      if (config.enabled === false) return null
      const items = Array.isArray(config.items) ? config.items.filter((item) => item && item.label) : []
      if (!items.length) return null

      return h(
        'div',
        { className: 'fgw-dock' },
        items.map((item, index) =>
          h(
            'button',
            {
              key: item.id || `${item.label}-${index}`,
              type: 'button',
              className: 'fgw-dock-chip',
              title: item.text ? `插入：${item.text}` : item.label,
              onClick: () => insertIntoComposer(item.text || item.label),
            },
            h(
              'span',
              { className: 'fgw-dock-mark', style: { background: chipColor(item, index) } },
              String(item.label).trim().slice(0, 1).toUpperCase(),
            ),
            item.label,
          ),
        ),
      )
    }

    ChipsDock.displayName = 'FreshGreenChipsDock'

    return {
      inject: ['theme', 'slots'],
      apply(ctx) {
        hostCtx = ctx
        ctx.effect(mountDom, 'fresh-green-skin: wallpaper')
        ctx.effect(installShortcuts, 'fresh-green-skin: shortcuts')

        if (ctx.slots && typeof ctx.slots.inject === 'function') {
          try {
            ctx.slots.inject('settings.general.item', () =>
              ctx.slots.register(
                { name: 'settings.general.item', id: 'fresh-green-wallpaper', order: 20 },
                ThemeRow,
              ),
            )
          } catch {
            /* a host without the general-settings slot simply gets no row */
          }
          try {
            ctx.slots.inject('conversation.input.dock', () =>
              ctx.slots.register(
                { name: 'conversation.input.dock', id: 'fresh-green-chips', order: 5 },
                ChipsDock,
              ),
            )
          } catch {
            /* older hosts have no composer dock: chips just do not show */
          }
        }
      },
    }
  },
})
