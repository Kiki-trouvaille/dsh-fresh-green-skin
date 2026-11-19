/**
 * Fresh white-green skin for the DSH web UI, with a gallery of built-in
 * wallpapers, a user-uploadable photo, and a live transparency slider.
 *
 * Layers:
 *  - theme tokens through the Client `theme` service (overrideTokens keeps
 *    light/dark/system switching intact, unlike register() which pins one scheme);
 *  - a fixed wallpaper painted behind the app frame, veiled by a white (light)
 *    or ink-green (dark) layer whose alpha is driven by the slider;
 *  - a "壁纸" row in 设置 → 通用 with preset thumbnails, upload and reset.
 *
 * Preferences live in localStorage of the web app origin, so they apply to
 * this browser profile without touching the Host config.
 *
 * Preset images are inlined as WebP data URIs by tools/build-client.py; edit
 * this template, not the generated client.js.
 */

const SOURCE = 'dsh-fresh-green-skin'
const IMAGE_KEY = 'fresh-green-skin:wallpaper'
const VEIL_KEY = 'fresh-green-skin:veil'

const DEFAULT_VEIL = 0.34

/** Injected by tools/build-client.py: [{ id, label, value }], value is a CSS background-image. */
const PRESETS = __PRESETS__

const DEFAULT_BG = PRESETS[0].value

const TOKENS = {
  '--dsw-alias-bg-base': { light: 'rgba(255,255,255,0)', dark: 'rgba(0,0,0,0)' },
  // Windows paints the whole app frame with the sidebar token, so it has to be
  // clear for the wallpaper to reach the content area (see CSS below, which
  // re-frosts the sidebar column itself).
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
}
body[data-ds-dark-theme][data-fresh-skin='on'] {
  background-color: #08120c !important;
  background-image:
    linear-gradient(rgba(6,12,9,var(--fgw-veil-dark,0.60)), rgba(6,12,9,var(--fgw-veil-dark,0.60))),
    var(--fgw-image, none) !important;
}
/* The frame token is transparent so the wallpaper shows; the sidebar keeps its
   own frosted panel so navigation text stays readable. Class hashes change
   between DSH builds, the "_sidebarCol" suffix does not. */
body[data-fresh-skin='on'] [class*='_sidebarCol'] { background: rgba(250,253,250,0.62) !important; }
body[data-ds-dark-theme][data-fresh-skin='on'] [class*='_sidebarCol'] { background: rgba(13,24,18,0.80) !important; }
.fgw-row {
  display: flex; align-items: center; gap: 16px;
  padding: 16px 0; border-bottom: .5px solid var(--dsw-alias-border-l2);
  color: var(--dsw-alias-label-primary);
}
.fgw-gallery { display: flex; align-items: center; gap: 8px; flex: none; }
.fgw-chip {
  width: 64px; height: 40px; padding: 0; flex: none; cursor: pointer;
  border-radius: 8px; border: 2px solid transparent;
  background-size: cover; background-position: center; background-repeat: no-repeat;
  box-shadow: inset 0 0 0 1px var(--dsw-alias-border-l2);
}
.fgw-chip.active {
  border-color: var(--dsw-alias-brand-primary);
  box-shadow: 0 0 0 2px rgba(46,139,87,.20);
}
.fgw-main { flex: 1; min-width: 0; }
.fgw-title { font-size: 14px; line-height: 20px; }
.fgw-actions { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; margin-top: 10px; }
.fgw-btn {
  font: inherit; font-size: 12px; line-height: 18px; padding: 5px 12px; border-radius: 8px;
  cursor: pointer; color: var(--dsw-alias-label-primary);
  background: var(--dsw-alias-bg-layer-3); border: 1px solid var(--dsw-alias-border-l2);
}
.fgw-btn.primary {
  color: #fff; border-color: transparent;
  background: var(--dsw-alias-brand-primary);
}
.fgw-btn:disabled { opacity: .55; cursor: default; }
.fgw-slider { display: flex; align-items: center; gap: 10px; margin-top: 10px; }
.fgw-slider input[type='range'] { flex: 1; max-width: 260px; accent-color: var(--dsw-alias-brand-primary); }
.fgw-value { font-size: 12px; color: var(--dsw-alias-label-secondary); min-width: 64px; }
.fgw-note { font-size: 12px; color: var(--dsw-alias-brand-primary); margin-top: 6px; }
`

// ---------------------------------------------------------------- state ----

const listeners = new Set()
let state = null

function defaults() {
  return { bg: DEFAULT_BG, veil: DEFAULT_VEIL }
}

/** Legacy builds stored the raw data URI instead of a full CSS background-image. */
function normalizeBg(value) {
  if (!value) return DEFAULT_BG
  return /^(url|linear-gradient|radial-gradient|conic-gradient)\(/.test(value) ? value : `url("${value}")`
}

function readStored() {
  const fallback = defaults()
  try {
    const bg = normalizeBg(localStorage.getItem(IMAGE_KEY))
    const storedVeil = localStorage.getItem(VEIL_KEY)
    const veil = storedVeil === null ? fallback.veil : Number(storedVeil)
    return {
      bg,
      veil: Number.isFinite(veil) ? Math.min(1, Math.max(0, veil)) : fallback.veil,
    }
  } catch {
    return fallback
  }
}

function getState() {
  if (!state) state = readStored()
  return state
}

function applyState(next) {
  const root = document.documentElement
  root.style.setProperty('--fgw-image', next.bg)
  root.style.setProperty('--fgw-veil', String(next.veil))
  root.style.setProperty('--fgw-veil-dark', String(next.veil))
}

let persistedBg = null

function persist(next) {
  try {
    if (next.bg.length > 4 * 1024 * 1024) throw new Error('图片太大，无法保存')
    if (persistedBg !== next.bg) {
      localStorage.setItem(IMAGE_KEY, next.bg)
      persistedBg = next.bg
    }
    localStorage.setItem(VEIL_KEY, String(next.veil))
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

/** Downscale a picked file so the stored data URI stays small. */
function readImageFile(file, done) {
  const reader = new FileReader()
  reader.onerror = () => done(new Error('读取文件失败'))
  reader.onload = () => {
    const image = new Image()
    image.onerror = () => done(new Error('这张图片无法解析'))
    image.onload = () => {
      const maxWidth = 1920
      const scale = Math.min(1, maxWidth / image.naturalWidth)
      const canvas = document.createElement('canvas')
      canvas.width = Math.max(1, Math.round(image.naturalWidth * scale))
      canvas.height = Math.max(1, Math.round(image.naturalHeight * scale))
      const context = canvas.getContext('2d')
      if (!context) return done(new Error('浏览器不支持 canvas'))
      context.drawImage(image, 0, 0, canvas.width, canvas.height)
      done(null, `url("${canvas.toDataURL('image/jpeg', 0.86)}")`)
    }
    image.src = String(reader.result)
  }
  reader.readAsDataURL(file)
}

// ------------------------------------------------------------ settings ----

function mountStyle() {
  const style = document.createElement('style')
  style.dataset.freshGreenSkin = 'on'
  style.textContent = CSS
  document.head.appendChild(style)
  document.body.dataset.freshSkin = 'on'
  applyState(getState())
  return () => {
    style.remove()
    delete document.body.dataset.freshSkin
  }
}

window.__ModuleLoader__.load({
  id: 'dsh-fresh-green-skin',
  factory(require) {
    const h = require('react').createElement
    const { useState, useEffect, useRef } = require('react')

    function WallpaperRow() {
      const [current, setCurrent] = useState(getState)
      const [note, setNote] = useState('')
      const fileRef = useRef(null)

      useEffect(() => {
        const listener = (next, failure) => {
          setCurrent(next)
          if (failure) setNote(`保存失败：${failure}`)
        }
        listeners.add(listener)
        return () => listeners.delete(listener)
      }, [])

      const transparency = Math.round(current.veil * 100)
      const isPreset = PRESETS.some((preset) => preset.value === current.bg)

      const pick = () => fileRef.current && fileRef.current.click()

      const choosePreset = (preset) => {
        setNote('')
        setState({ ...current, bg: preset.value })
      }

      const onFile = (event) => {
        const file = event.target.files && event.target.files[0]
        event.target.value = ''
        if (!file) return
        setNote('正在处理图片…')
        readImageFile(file, (error, value) => {
          if (error || !value) {
            setNote(`换图失败：${error ? error.message : '未知错误'}`)
            return
          }
          const failure = setState({ ...current, bg: value })
          setNote(failure ? `换图失败：${failure}` : '壁纸已更换')
        })
      }

      const reset = () => {
        const failure = setState(defaults())
        setNote(failure ? `恢复失败：${failure}` : '已恢复默认壁纸')
      }

      const chips = PRESETS.map((preset) =>
        h('button', {
          key: preset.id,
          type: 'button',
          className: `fgw-chip${current.bg === preset.value ? ' active' : ''}`,
          title: preset.label,
          'aria-label': preset.label,
          style: { backgroundImage: preset.value },
          onClick: () => choosePreset(preset),
        }),
      )
      if (!isPreset) {
        chips.push(
          h('button', {
            key: 'custom',
            type: 'button',
            className: 'fgw-chip active',
            title: '我的图片',
            'aria-label': '我的图片',
            style: { backgroundImage: current.bg },
            onClick: pick,
          }),
        )
      }

      return h(
        'div',
        { className: 'fgw-row' },
        h('div', { className: 'fgw-gallery' }, chips),
        h(
          'div',
          { className: 'fgw-main' },
          h('div', { className: 'fgw-title' }, '壁纸'),
          h(
            'div',
            { className: 'fgw-slider' },
            h('span', { className: 'fgw-value' }, '透明度'),
            h('input', {
              type: 'range',
              min: 0,
              max: 100,
              step: 1,
              value: transparency,
              onChange: (event) => {
                const next = Math.min(1, Math.max(0, Number(event.target.value) / 100))
                setState({ ...current, veil: next })
                setNote('')
              },
            }),
            h('span', { className: 'fgw-value' }, `${transparency}%`),
          ),
          h(
            'div',
            { className: 'fgw-actions' },
            h('button', { className: 'fgw-btn primary', onClick: pick }, '上传图片'),
            h('button', { className: 'fgw-btn', onClick: reset }, '恢复默认'),
            h('input', {
              ref: fileRef,
              type: 'file',
              accept: 'image/*',
              style: { display: 'none' },
              onChange: onFile,
            }),
          ),
          note ? h('div', { className: 'fgw-note' }, note) : null,
        ),
      )
    }

    WallpaperRow.displayName = 'FreshGreenWallpaperRow'

    return {
      inject: ['theme', 'slots'],
      apply(ctx) {
        ctx.effect(mountStyle, 'fresh-green-skin: wallpaper')

        if (ctx.theme && typeof ctx.theme.overrideTokens === 'function') {
          ctx.effect(() => ctx.theme.overrideTokens(SOURCE, TOKENS), 'fresh-green-skin: tokens')
        }

        if (ctx.slots && typeof ctx.slots.inject === 'function') {
          ctx.slots.inject('settings.general.item', () =>
            ctx.slots.register(
              { name: 'settings.general.item', id: 'fresh-green-wallpaper', order: 20 },
              WallpaperRow,
            ),
          )
        }
      },
    }
  },
})
