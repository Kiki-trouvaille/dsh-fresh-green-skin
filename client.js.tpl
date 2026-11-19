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
    linear-gradient(rgba(var(--fgw-scrim, 255,255,255),var(--fgw-veil,${DEFAULT_VEIL})), rgba(var(--fgw-scrim, 255,255,255),var(--fgw-veil,${DEFAULT_VEIL}))),
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
    linear-gradient(rgba(var(--fgw-scrim-dark, 6,12,9),var(--fgw-veil-dark,0.60)), rgba(var(--fgw-scrim-dark, 6,12,9),var(--fgw-veil-dark,0.60))),
    var(--fgw-image, none) !important;
}
/* Video wallpaper sits behind everything; the veil is a sibling overlay. */
.fgw-video { position: fixed; inset: 0; width: 100%; height: 100%; object-fit: cover; z-index: -2; pointer-events: none; }
.fgw-video-veil {
  position: fixed; inset: 0; z-index: -1; pointer-events: none;
  background: rgba(var(--fgw-scrim, 255,255,255),var(--fgw-veil,${DEFAULT_VEIL}));
}
body[data-ds-dark-theme] .fgw-video-veil { background: rgba(var(--fgw-scrim-dark, 6,12,9),var(--fgw-veil-dark,0.60)); }
/* The frame token is transparent so the wallpaper shows; the sidebar keeps its
   own frosted panel so navigation text stays readable. */
body[data-fresh-skin='on'] [class*='_sidebarCol'] { background: var(--fgw-sidebar, rgba(250,253,250,0.62)) !important; }
body[data-ds-dark-theme][data-fresh-skin='on'] [class*='_sidebarCol'] { background: var(--fgw-sidebar, rgba(13,24,18,0.80)) !important; }
/* Windows paints the titlebar strip from the sidebar fill, so the same tint keeps
   the top bar and the sidebar reading as one surface instead of two panels. */
body[data-fresh-skin='on'] [class*='_frame']::before { background: var(--fgw-topbar, var(--fgw-sidebar, rgba(250,253,250,0.62))) !important; }
body[data-ds-dark-theme][data-fresh-skin='on'] [class*='_frame']::before { background: var(--fgw-topbar, var(--fgw-sidebar, rgba(13,24,18,0.80))) !important; }
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
.fgw-label { width: 56px; flex: none; font-size: 13px; }
.fgw-label.auto { width: auto; white-space: nowrap; }
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
.fgw-toggle { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; color: var(--dsw-alias-label-secondary); cursor: pointer; white-space: nowrap; }
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
.fgw-hint { white-space: nowrap; font-size: 11px; color: var(--dsw-alias-label-tertiary); }
.fgw-presets { display: flex; flex-wrap: wrap; gap: 8px; }
.fgw-preset {
  display: flex; flex-direction: column; align-items: flex-start; gap: 2px; cursor: pointer;
  font: inherit; text-align: left; padding: 7px 12px; border-radius: 10px;
  color: var(--dsw-alias-label-primary);
  background: var(--dsw-alias-bg-layer-3); border: 1px solid var(--dsw-alias-border-l2);
}
.fgw-preset small { font-size: 11px; color: var(--dsw-alias-label-tertiary); }
.fgw-preset.active { border-color: var(--dsw-alias-brand-primary); box-shadow: 0 0 0 2px rgba(46,139,87,.18); }
.fgw-preset-dot { width: 34px; height: 6px; border-radius: 3px; margin-bottom: 2px; }
.fgw-brand-icon { display: block; width: 100%; height: 100%; object-fit: contain; }
.fgw-thumb-logo { object-fit: contain; border-radius: 6px; }
/* A custom logo replaces the whale the host draws on its canvas. */
body[data-fgw-logo='on'] canvas[data-home-whale],
body[data-fgw-hide-whale='on'] canvas[data-home-whale] { display: none !important; }
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
  const rgb = hexToRgb(value)
  if (!rgb) return value
  return `rgba(${rgb.r},${rgb.g},${rgb.b},${ratio})`
}

/** '#2e8b57' -> { r: 46, g: 139, b: 87 }, or null when it is not a hex colour. */
function hexToRgb(color) {
  const hex = String(color || '').trim().match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i)
  if (!hex) return null
  let digits = hex[1]
  if (digits.length === 3) digits = digits.split('').map((ch) => ch + ch).join('')
  return {
    r: parseInt(digits.slice(0, 2), 16),
    g: parseInt(digits.slice(2, 4), 16),
    b: parseInt(digits.slice(4, 6), 16),
  }
}

/** Blend two hex colours: t=0 keeps a, t=1 keeps b. Falls back to a when unparsable. */
function mixHex(a, b, t) {
  const one = hexToRgb(a)
  const two = hexToRgb(b)
  if (!one || !two) return a
  const ratio = clamp(Number(t), 0, 1)
  const channel = (x, y) => Math.round(x + (y - x) * ratio).toString(16).padStart(2, '0')
  return `#${channel(one.r, two.r)}${channel(one.g, two.g)}${channel(one.b, two.b)}`
}

/** Luminance of whichever wallpaper is showing right now, 0 (black) to 1 (white).
    Sampling happens for every source, so this works for photos and video frames
    alike; 0.62 is a neutral middle when nothing could be sampled yet. */
function wallpaperLuminance() {
  const sample = runtime.derived && runtime.derived.sample
  const value = sample ? Number(sample.luminance) : NaN
  return Number.isFinite(value) ? clamp(value, 0, 1) : 0.62
}

/** Veil strength that pushes the wallpaper behind the text to a readable floor:
    a white scrim lifts it towards 0.78, a dark scrim drops it to 0.16. Small
    floors keep the wallpaper visible on already-safe photos, and strong veils
    save really bright or really dark ones. */
function contrastVeil(photo, mode) {
  // Light mode only needs to lift the photo to a mid tone: dark ink on 0.68 has
  // well over 10:1 contrast, so the wallpaper keeps more of its colour. Dark
  // mode needs a deeper scrim because light ink is less forgiving.
  if (mode === 'dark') {
    const veil = photo <= 0.16 ? 0.12 : (photo - 0.16) / Math.max(photo, 0.001)
    return clamp(veil, 0.1, 0.94)
  }
  const veil = photo >= 0.68 ? 0.12 : (0.68 - photo) / Math.max(1 - photo, 0.001)
  return clamp(veil, 0.1, 0.94)
}

/** System palettes: a handful of neutral papers, so "follow the system" is not a
    single grey. `dark` tones paint dark panels and switch the text to light ink. */
const SYSTEM_TONES = [
  { id: 'neutral', label: '中性灰', paper: '#f4f5f4', dark: false },
  { id: 'cool', label: '冷白', paper: '#eef3f7', dark: false },
  { id: 'warm', label: '暖白', paper: '#f7f3ec', dark: false },
  { id: 'slate', label: '雾灰', paper: '#e7ebe9', dark: false },
  { id: 'ink', label: '墨黑', paper: '#20262a', dark: true },
]

function systemTone(next) {
  return SYSTEM_TONES.find((tone) => tone.id === next.tone) || SYSTEM_TONES[0]
}

/** Pick readable text for a surface of the given luminance. */
function inkFor(surfaceLuminance) {
  return surfaceLuminance > 0.5 ? '#0f1c14' : '#f2faf5'
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
const runtime = { video: null, videoUrl: null, veilCss: null, tokens: null, logoComponent: null }
const logoHandles = []
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
    topbarClear: false,
    neutralAccent: false,
    tone: 'neutral',
    autoContrast: true,
    sidebarFill: true,
    paper: '',
    logo: '',
    hideWhale: false,
    colors: { brand: '', sidebar: '', bubble: '', text: '', whale: '', wordmark: '' },
    alpha: { sidebar: 62, bubble: 88 },
    chips: { enabled: true, items: [] },
    font: '',
  }
}

/** One-click looks. Each entry only sets the fields it cares about. */
const QUICK_PRESETS = [
  {
    id: 'fresh',
    label: '清爽白绿',
    hint: '照片 + 白纸 + 绿点缀',
    dot: 'linear-gradient(90deg,#fdfefd,#2e8b57)',
    value: { palette: 'theme', veil: 0.34, alpha: { sidebar: 62, bubble: 88 }, paper: '', topbarClear: false, colors: { brand: '', sidebar: '', bubble: '', text: '' } },
  },
  {
    id: 'photo',
    label: '全壁纸',
    hint: '几乎不遮，颜色跟着照片走',
    dot: 'linear-gradient(90deg,#9ec9b4,#2e8b57)',
    value: { palette: 'image', veil: 0.1, alpha: { sidebar: 26, bubble: 46 }, paper: '', topbarClear: true },
  },
  {
    id: 'system',
    label: '跟随系统',
    hint: '中性和纸，字色自动保证对比',
    dot: 'linear-gradient(90deg,#f4f4f2,#b7bcb9)',
    value: { palette: 'system', tone: 'neutral', veil: 0.34, alpha: { sidebar: 62, bubble: 88 }, paper: '', neutralAccent: true, autoContrast: true },
  },
  {
    id: 'plain',
    label: '纯纸面',
    hint: '收掉壁纸，只留配色',
    dot: 'linear-gradient(90deg,#ffffff,#eef3ef)',
    value: { palette: 'custom', veil: 1, alpha: { sidebar: 100, bubble: 100 }, colors: { brand: '', sidebar: '#f7faf8', bubble: '#ffffff', text: '' }, paper: '' },
  },
]

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

/** The two scrims the CSS paints: light mode over the photo, dark mode under it.
    With automatic contrast the strength comes from the wallpaper luminance, so
    text stays readable on any photo or video; the page can still be darkened by
    hand once the option is switched off. */
function resolveVeils(next) {
  const manual = resolveVeil(next)
  if (next.autoContrast === false) return { light: manual, dark: manual }
  const photo = wallpaperLuminance()
  if (next.palette === 'image') {
    // Light mode uses dark ink, dark mode light ink: each mode gets the scrim
    // that pushes the photo towards its own readable side.
    return { light: contrastVeil(photo, 'light'), dark: contrastVeil(photo, 'dark') }
  }
  if (next.palette === 'system') {
    const tone = systemTone(next)
    const derived = contrastVeil(photo, tone.dark ? 'dark' : 'light')
    return { light: derived, dark: derived }
  }
  return { light: manual, dark: manual }
}

function buildTokens(next) {
  const tokens = JSON.parse(JSON.stringify(BASE_TOKENS))
  const sample = next.palette === 'image' ? runtime.derived : null
  const colors = next.colors || {}
  const alpha = next.alpha || {}

  if (next.palette === 'system') {
    // Follow one of the neutral system papers: the panels take the paper tone at
    // the two opacity sliders, and the text colour comes from the paper itself
    // (not from the wallpaper), so panels and prose stay readable together.
    const tone = systemTone(next)
    const paper = tone.paper
    const ink = tone.dark ? '#f2faf5' : '#0f1c14'
    const rest = tone.dark ? 'rgba(255,255,255,' : 'rgba(15,28,20,'
    tokens['--dsw-alias-bg-layer-1'] = {
      light: withAlpha(paper, alpha.sidebar),
      dark: withAlpha(paper, alpha.sidebar),
    }
    tokens['--dsw-alias-bg-layer-2'] = {
      light: withAlpha(paper, alpha.bubble),
      dark: withAlpha(paper, alpha.bubble),
    }
    tokens['--dsw-alias-bg-layer-3'] = {
      light: withAlpha(paper, Math.min(100, Number(alpha.bubble) + 10)),
      dark: withAlpha(paper, Math.min(100, Number(alpha.bubble) + 10)),
    }
    tokens['--dsw-alias-border-l1'] = { light: `${rest}0.12)`, dark: `${rest}0.18)` }
    tokens['--dsw-alias-border-l2'] = { light: `${rest}0.18)`, dark: `${rest}0.24)` }
    tokens['--dsw-alias-border-l3'] = { light: `${rest}0.26)`, dark: `${rest}0.32)` }
    tokens['--dsw-alias-label-primary'] = { light: ink, dark: ink }
    tokens['--dsw-alias-label-secondary'] = { light: tone.dark ? '#c9d6cf' : '#3d5346', dark: tone.dark ? '#c9d6cf' : '#3d5346' }
    tokens['--dsw-alias-label-tertiary'] = { light: tone.dark ? '#9fb0a8' : '#63806f', dark: tone.dark ? '#9fb0a8' : '#63806f' }
    if (next.neutralAccent) {
      // Some people want the host look end to end: drop the green accent too.
      const slate = tone.dark ? '#a9c3b6' : '#4c5f56'
      tokens['--dsw-alias-brand-primary'] = { light: slate, dark: slate }
      tokens['--dsw-alias-state-business-primary'] = { light: slate, dark: slate }
    }
  }

  if (next.palette === 'image') {
    // The prose sits on the *veiled* wallpaper, not on the raw photo, so the ink
    // has to follow the surface that the veil produces. contrastVeil normalises
    // that surface, which keeps text readable on bright and dark photos alike.
    const veils = resolveVeils(next)
    const photo = wallpaperLuminance()
    const lightSurface = photo * (1 - veils.light) + veils.light
    const darkSurface = photo * (1 - veils.dark) + 0.04 * veils.dark
    tokens['--dsw-alias-label-primary'] = { light: inkFor(lightSurface), dark: inkFor(darkSurface) }
    tokens['--dsw-alias-label-secondary'] = {
      light: mixHex(inkFor(lightSurface), '#ffffff', 0.35),
      dark: mixHex(inkFor(darkSurface), '#000000', 0.25),
    }
    tokens['--dsw-alias-label-tertiary'] = {
      light: mixHex(inkFor(lightSurface), '#ffffff', 0.58),
      dark: mixHex(inkFor(darkSurface), '#000000', 0.45),
    }
    if (sample) {
      tokens['--dsw-alias-brand-primary'] = { light: sample.brand, dark: sample.brandDark }
      tokens['--dsw-alias-state-business-primary'] = { light: sample.brand, dark: sample.brandDark }
      tokens['--dsw-alias-state-success-primary'] = { light: sample.brand, dark: sample.brandDark }
      tokens['--dsw-alias-bg-layer-2'] = { light: sample.bubble, dark: 'rgba(24,38,30,0.88)' }
      tokens['--dsw-alias-bg-layer-3'] = { light: sample.bubble, dark: 'rgba(30,46,37,0.93)' }
    }
  }

  if (next.paper) {
    // One anchor colour ("纸面") drives the whole surface stack: panels, borders
    // and the two secondary label tiers are all derived from it, so a custom
    // palette needs one decision instead of eight.
    const paper = String(next.paper)
    const accent = colors.brand || (sample ? sample.brand : '#2e8b57')
    const paperVeils = resolveVeils(next)
    const paperPhoto = wallpaperLuminance()
    const paperSurface = paperPhoto * (1 - paperVeils.light) + paperVeils.light
    const text = colors.text || (sample ? inkFor(paperSurface) : '#0f1c14')
    const darkPaper = mixHex(paper, '#0a110c', 0.82)
    const darkText = '#eaf5ee'
    tokens['--dsw-alias-bg-layer-1'] = { light: withAlpha(paper, alpha.sidebar), dark: withAlpha(darkPaper, alpha.sidebar) }
    tokens['--dsw-alias-bg-layer-2'] = { light: withAlpha(paper, alpha.bubble), dark: withAlpha(darkPaper, alpha.bubble) }
    tokens['--dsw-alias-bg-layer-3'] = { light: withAlpha(paper, Math.min(100, Number(alpha.bubble) + 10)), dark: withAlpha(darkPaper, 96) }
    tokens['--dsw-alias-border-l1'] = { light: withAlpha(accent, 16), dark: 'rgba(126,215,166,0.18)' }
    tokens['--dsw-alias-border-l2'] = { light: withAlpha(accent, 22), dark: 'rgba(126,215,166,0.24)' }
    tokens['--dsw-alias-border-l3'] = { light: withAlpha(accent, 30), dark: 'rgba(126,215,166,0.32)' }
    tokens['--dsw-alias-label-secondary'] = { light: mixHex(text, paper, 0.45), dark: '#c2d8c9' }
    tokens['--dsw-alias-label-tertiary'] = { light: mixHex(text, paper, 0.66), dark: '#93ab9c' }
    tokens['--dsw-alias-label-primary'] = { light: text, dark: darkText }
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
  const veils = resolveVeils(next)
  root.style.setProperty('--fgw-veil', String(veils.light))
  root.style.setProperty('--fgw-veil-dark', String(veils.dark))
  // A dark paper needs a light ink, so its scrim darkens; a light paper lifts the
  // photo towards white instead. Both scrims are variables for exactly that reason.
  const tone = next.palette === 'system' ? systemTone(next) : null
  if (tone) {
    const scrim = tone.dark ? '6,12,9' : '255,255,255'
    root.style.setProperty('--fgw-scrim', scrim)
    root.style.setProperty('--fgw-scrim-dark', scrim)
  } else {
    root.style.removeProperty('--fgw-scrim')
    root.style.removeProperty('--fgw-scrim-dark')
  }
  root.style.setProperty('--fgw-image', backgroundCss(next))
  root.style.setProperty('--fgw-font', next.font || 'inherit')

  const colors = next.colors || {}
  const alpha = next.alpha || {}
  // The paper anchor doubles as the sidebar tint, so one colour choice keeps the
  // frame, the sidebar strip and the panels in the same family.
  const sidebar = colors.sidebar || (tone ? tone.paper : next.paper)
  if (next.sidebarFill === false) root.style.setProperty('--fgw-sidebar', 'transparent')
  else if (sidebar) root.style.setProperty('--fgw-sidebar', withAlpha(sidebar, alpha.sidebar))
  else root.style.removeProperty('--fgw-sidebar')
  // "透明顶栏": let the wallpaper run to the very top, keeping the sidebar frosted.
  if (next.topbarClear) root.style.setProperty('--fgw-topbar', 'transparent')
  else root.style.removeProperty('--fgw-topbar')

  if (colors.whale) root.style.setProperty('--fgw-whale', colors.whale)
  else root.style.removeProperty('--fgw-whale')
  if (next.brandTint && colors.wordmark) root.style.setProperty('--fgw-brandtext', colors.wordmark)
  else root.style.removeProperty('--fgw-brandtext')

  const body = document.body
  if (body) {
    body.dataset.freshSkin = 'on'
    if (next.brandTint && colors.wordmark) body.dataset.fgwBrandTint = 'on'
    else delete body.dataset.fgwBrandTint
    if (next.logo) body.dataset.fgwLogo = 'on'
    else delete body.dataset.fgwLogo
    if (next.hideWhale) body.dataset.fgwHideWhale = 'on'
    else delete body.dataset.fgwHideWhale
    if (next.source.kind === 'video') body.dataset.fgwVideo = 'on'
    else delete body.dataset.fgwVideo
  }

  applyTokens(next)
  syncVideo(next)
  syncLogo(next)
}

/** Swap the host's brand marks for the user's own logo, but only while one is set:
    registering on demand keeps the shipped whale for everybody who never uploads. */
function syncLogo(next) {
  const hasLogo = Boolean(next && next.logo)
  if (!hasLogo) {
    while (logoHandles.length) {
      const dispose = logoHandles.pop()
      try {
        dispose()
      } catch {
        /* already gone */
      }
    }
    return
  }
  if (logoHandles.length || !hostCtx || !hostCtx.slots || typeof hostCtx.slots.inject !== 'function') return
  const component = runtime.logoComponent
  if (!component) return
  for (const name of ['sidebar.brand.mark', 'conversation.hero.brand.mark']) {
    try {
      const handle = hostCtx.slots.inject(name, () =>
        hostCtx.slots.register({ name, id: 'fresh-green-logo' }, component),
      )
      if (handle) logoHandles.push(handle)
    } catch {
      /* slot missing on this build: the logo simply does not replace anything */
    }
  }
}

function syncVideo(next) {  const wantsVideo = next.source.kind === 'video' && runtime.videoUrl
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
    // Everything except the video blob (which lives in IndexedDB) and the image
    // bytes of an uploaded photo, which stay in `source.src`.
    const copy = {
      ...next,
      colors: { ...(next.colors || {}) },
      alpha: { ...(next.alpha || {}) },
      chips: { ...(next.chips || {}) },
    }
    delete copy.hostCtx
    if (copy.source && copy.source.kind === 'video') copy.source = { kind: 'video', name: copy.source.name || 'video' }
    if (copy.source && copy.source.kind === 'image' && copy.source.src && copy.source.src.length > 4 * 1024 * 1024) {
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

/** Brand logo: small, square-ish PNG so it stays crisp on the 24/34 px marks. */
function readLogoFile(file, done) {
  const reader = new FileReader()
  reader.onerror = () => done(new Error('读取文件失败'))
  reader.onload = () => {
    const image = new Image()
    image.onerror = () => done(new Error('这张图片无法解析'))
    image.onload = () => {
      const scale = Math.min(1, 96 / Math.max(image.naturalWidth, image.naturalHeight))
      const canvas = document.createElement('canvas')
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale))
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale))
      const context = canvas.getContext('2d')
      if (!context) return done(new Error('浏览器不支持 canvas'))
      context.drawImage(image, 0, 0, canvas.width, canvas.height)
      done(null, canvas.toDataURL('image/png'))
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

// ------------------------------------------------------------- sharing ----

/** One file the user can hand to somebody else: current look plus saved themes. */
function exportThemeFile() {
  const payload = {
    app: SOURCE,
    version: 1,
    exportedAt: new Date().toISOString(),
    state: { ...getState() },
    themes: readThemes(),
  }
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = 'fresh-green-theme.json'
  document.body.appendChild(link)
  link.click()
  link.remove()
  setTimeout(() => URL.revokeObjectURL(url), 4000)
}

/** Accepts both our own export and a bare { value } snapshot. */
function readThemeFile(file, done) {
  const reader = new FileReader()
  reader.onerror = () => done(new Error('读取文件失败'))
  reader.onload = () => {
    try {
      const data = JSON.parse(String(reader.result))
      if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('不是主题文件')
      done(null, data)
    } catch (error) {
      done(error instanceof Error ? error : new Error(String(error)))
    }
  }
  reader.readAsText(file)
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
      const logoRef = useRef(null)
      const themeFileRef = useRef(null)

      useEffect(() => {
        const listener = (next, failure) => {
          setCurrent({ ...next })
          if (failure) setNote(`保存失败：${failure}`)
        }
        listeners.add(listener)
        return () => listeners.delete(listener)
      }, [])

      // What the eye actually sees: in "follow the system" mode the scrim is
      // derived from the wallpaper, so show that number instead of the raw slider.
      const veil = Math.round(resolveVeils(current).light * 100)
      const autocontrast = (current.palette === 'system' || current.palette === 'image') && current.autoContrast !== false

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

      /** One click sets a whole look, so nobody has to tune eight knobs first. */
      const applyQuickPreset = (preset) => {
        const value = preset.value || {}
        const next = {
          ...current,
          palette: value.palette || current.palette,
          veil: value.veil === undefined ? current.veil : value.veil,
          autoVeil: false,
          paper: value.paper === undefined ? current.paper : value.paper,
          topbarClear: value.topbarClear === undefined ? current.topbarClear : value.topbarClear,
          neutralAccent: value.neutralAccent === undefined ? current.neutralAccent : value.neutralAccent,
          alpha: { ...(current.alpha || {}), ...(value.alpha || {}) },
          colors: { ...(current.colors || {}), ...(value.colors || {}) },
        }
        setState(next)
        sampleSource(next)
        setNote(`已应用「${preset.label}」`)
      }

      const pickLogo = () => logoRef.current && logoRef.current.click()

      const onLogo = (event) => {
        const file = event.target.files && event.target.files[0]
        event.target.value = ''
        if (!file) return
        readLogoFile(file, (error, value) => {
          if (error || !value) {
            setNote(`图标读取失败：${error ? error.message : '未知错误'}`)
            return
          }
          const failure = setState({ ...current, logo: value })
          setNote(failure ? `图标保存失败：${failure}` : '已换成你的图标（侧栏与新会话）')
        })
      }

      const exportJson = () => {
        try {
          exportThemeFile()
          setNote('已导出 fresh-green-theme.json')
        } catch (error) {
          setNote(`导出失败：${error instanceof Error ? error.message : error}`)
        }
      }

      const importJson = () => themeFileRef.current && themeFileRef.current.click()

      const onThemeFile = (event) => {
        const file = event.target.files && event.target.files[0]
        event.target.value = ''
        if (!file) return
        readThemeFile(file, (error, data) => {
          if (error || !data) {
            setNote(`导入失败：${error ? error.message : '文件读不出来'}`)
            return
          }
          const incoming = data.state || data.value || (data.palette || data.source ? data : null)
          const merged = Array.isArray(data.themes) ? data.themes.filter((item) => item && item.name) : []
          if (merged.length) {
            const next = [...readThemes().filter((item) => !merged.some((extra) => extra.name === item.name)), ...merged]
            writeThemes(next)
            setThemes(next)
          }
          if (!incoming) {
            setNote(merged.length ? `已导入 ${merged.length} 套主题` : '这个文件里没有可用的配色')
            return
          }
          const next = { ...defaults(), ...incoming }
          setState(next)
          sampleSource(next)
          setNote(`已导入配色${merged.length ? `和 ${merged.length} 套主题` : ''}`)
        })
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
          { className: 'fgw-line fgw-stack' },
          h(
            'div',
            { className: 'fgw-actions' },
            h('span', { className: 'fgw-label auto' }, '一键预设'),
            h('span', { className: 'fgw-hint' }, '先挑一个整体观感，再往下微调'),
          ),
          h(
            'div',
            { className: 'fgw-presets' },
            QUICK_PRESETS.map((preset) =>
              h(
                'button',
                {
                  key: preset.id,
                  type: 'button',
                  className: 'fgw-preset',
                  title: preset.hint,
                  onClick: () => applyQuickPreset(preset),
                },
                h('span', { className: 'fgw-preset-dot', style: { background: preset.dot } }),
                preset.label,
                h('small', null, preset.hint),
              ),
            ),
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
              disabled: current.autoVeil || autocontrast,
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
            autocontrast
              ? h('span', { className: 'fgw-hint' }, '按壁纸明暗自动定遮罩，保证字看得清')
              : null,
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
            current.palette === 'system'
              ? h(
                  'label',
                  { className: 'fgw-toggle', title: '把绿色强调色也换成中性灰，整套更接近宿主原样' },
                  h('input', {
                    type: 'checkbox',
                    checked: Boolean(current.neutralAccent),
                    onChange: (event) => setState({ ...current, neutralAccent: event.target.checked }),
                  }),
                  '中性强调色',
                )
              : null,
            current.palette === 'system' || current.palette === 'image'
              ? h(
                  'label',
                  { className: 'fgw-toggle', title: '壁纸太亮或太暗时自动加深遮罩，保证正文和面板文字都看得清' },
                  h('input', {
                    type: 'checkbox',
                    checked: current.autoContrast !== false,
                    onChange: (event) => setState({ ...current, autoContrast: event.target.checked }),
                  }),
                  '自动保证对比',
                )
              : null,
          ),
          current.palette === 'system'
            ? h(
                'div',
                { className: 'fgw-actions fgw-inline' },
                h('span', { className: 'fgw-label auto' }, '系统色'),
                ...SYSTEM_TONES.map((tone) =>
                  h(
                    'button',
                    {
                      key: tone.id,
                      type: 'button',
                      className: `fgw-btn${(current.tone || SYSTEM_TONES[0].id) === tone.id ? ' primary' : ''}`,
                      title: tone.dark ? '深色纸面，正文自动转浅色字' : '浅色纸面，正文保持深色字',
                      onClick: () => setState({ ...current, tone: tone.id }),
                    },
                    h('span', {
                      className: 'fgw-swatch',
                      style: { background: tone.paper, display: 'inline-block', width: '14px', height: '14px', borderRadius: '4px', marginRight: '6px', verticalAlign: '-2px' },
                    }),
                    tone.label,
                  ),
                ),
              )
            : null,
          h(
            'div',
            { className: 'fgw-actions fgw-inline' },
            ...[
              ['brand', '主色'],
              ['paper', '纸面'],
              ['sidebar', '侧栏'],
              ['bubble', '气泡'],
              ['text', '文字'],
            ].map(([key, label]) => {
              const value = key === 'paper' ? current.paper : current.colors[key]
              const fallback = key === 'paper' ? '#f2f7f3' : '#2e8b57'
              const commit = (color) => {
                if (key === 'paper') setState({ ...current, paper: color })
                else setColors({ [key]: color })
              }
              return h(
                'label',
                { key, className: 'fgw-toggle', title: label },
                label,
                h('input', {
                  type: 'color',
                  className: 'fgw-swatch',
                  disabled: !colorEnabled,
                  value: value || fallback,
                  onChange: (event) => commit(event.target.value),
                }),
                h(
                  'button',
                  {
                    type: 'button',
                    className: 'fgw-btn',
                    title: '从壁纸取色',
                    disabled: !colorEnabled,
                    onClick: () =>
                      pickColorFromWallpaper(current, (color) => {
                        if (color) commit(color)
                      }),
                  },
                  '取色',
                ),
              )
            }),
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
          h('span', { className: 'fgw-label' }, ''),
          h(
            'label',
            { className: 'fgw-toggle', title: '关掉后侧栏完全不铺色，壁纸直接透上来；开着则按上面的百分比铺填充色' },
            h('input', {
              type: 'checkbox',
              checked: current.sidebarFill !== false,
              onChange: (event) => setState({ ...current, sidebarFill: event.target.checked }),
            }),
            '侧栏填充',
          ),
          h(
            'label',
            { className: 'fgw-toggle', title: '顶栏不铺磨砂，让照片一直铺到最上面' },
            h('input', {
              type: 'checkbox',
              checked: Boolean(current.topbarClear),
              onChange: (event) => setState({ ...current, topbarClear: event.target.checked }),
            }),
            '顶栏透明',
          ),
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
          { className: 'fgw-line' },
          h('span', { className: 'fgw-label' }, '图标'),
          h(
            'label',
            { className: 'fgw-toggle', title: '没有图标时用宿主原来的鲸鱼' },
            h('input', {
              type: 'checkbox',
              checked: Boolean(current.hideWhale),
              onChange: (event) => setState({ ...current, hideWhale: event.target.checked }),
            }),
            '隐藏大鲸鱼',
          ),
          h('span', { className: 'fgw-hint' }, current.logo ? '已用你的图标替换侧栏与新会话标识' : '可上传 PNG/SVG 做自己的标识'),
          h('button', { className: 'fgw-btn', onClick: pickLogo }, current.logo ? '更换图标' : '上传图标'),
          current.logo
            ? h('button', { className: 'fgw-btn', onClick: () => setState({ ...current, logo: '' }) }, '移除')
            : null,
          current.logo
            ? h(
                'img',
                { className: 'fgw-thumb-logo', src: current.logo, alt: '', style: { width: '26px', height: '26px' } },
              )
            : null,
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
          h('button', { className: 'fgw-btn', title: '把当前配色和已存主题导出成一个 JSON 文件', onClick: exportJson }, '导出'),
          h('button', { className: 'fgw-btn', title: '从别人分享的 JSON 导入配色', onClick: importJson }, '导入'),
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
        h('input', {
          ref: logoRef,
          type: 'file',
          accept: 'image/png,image/svg+xml,image/webp,image/jpeg',
          style: { display: 'none' },
          onChange: onLogo,
        }),
        h('input', {
          ref: themeFileRef,
          type: 'file',
          accept: 'application/json,.json',
          style: { display: 'none' },
          onChange: onThemeFile,
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

    /** Stands in for the host's brand mark while a custom logo is uploaded. */
    function BrandIcon(props) {
      const [current, setCurrent] = useState(getState)
      useEffect(() => {
        const listener = (next) => setCurrent({ ...next })
        listeners.add(listener)
        return () => listeners.delete(listener)
      }, [])

      if (!current.logo) return null
      const size = props && props.size ? Number(props.size) : 24
      return h('img', {
        className: 'fgw-brand-icon',
        src: current.logo,
        alt: '',
        style: { width: `${size}px`, height: `${size}px` },
      })
    }

    BrandIcon.displayName = 'FreshGreenBrandIcon'
    runtime.logoComponent = BrandIcon

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
