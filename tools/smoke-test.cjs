/**
 * Offline smoke test for the generated client bundle.
 *
 * Run:  node tools/smoke-test.cjs
 *
 * It emulates just enough of the DSH web client (window.__ModuleLoader__,
 * document, localStorage, react) to catch the failures that are invisible in a
 * browser until the settings row silently disappears:
 *   - the bundle registers the expected service injections;
 *   - the theme tokens are handed to `theme.overrideTokens`;
 *   - the "壁纸" row is registered on settings.general.item;
 *   - and the row component actually RENDERS without throwing.
 */

const fs = require('node:fs')
const path = require('node:path')
const vm = require('node:vm')

const root = path.dirname(__dirname)
const source = fs.readFileSync(path.join(root, 'client.js'), 'utf8')

const failures = []
const check = (ok, label) => {
  if (!ok) failures.push(label)
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${label}`)
}

// --- fake DOM -------------------------------------------------------------
const styleNodes = []
const bodyProps = {}
const cssVars = new Map()

const fakeStyle = {
  setProperty(name, value) {
    cssVars.set(name, value)
  },
  removeProperty(name) {
    cssVars.delete(name)
  },
}

const makeElement = (tag) => ({
  tagName: String(tag).toUpperCase(),
  textContent: '',
  className: '',
  dataset: {},
  style: fakeStyle,
  children: [],
  appendChild(child) {
    this.children.push(child)
    return child
  },
  remove() {},
  setAttribute() {},
  play() {
    return Promise.resolve()
  },
  addEventListener() {},
  removeEventListener() {},
})

const document = {
  head: makeElement('head'),
  body: makeElement('body'),
  documentElement: { dataset: {}, style: fakeStyle },
  createElement: (tag) => makeElement(tag),
  querySelector: () => null,
}
document.head.appendChild = (node) => {
  styleNodes.push(node)
  return node
}

const store = new Map()
const localStorage = {
  getItem: (key) => (store.has(key) ? store.get(key) : null),
  setItem: (key, value) => store.set(key, String(value)),
  removeItem: (key) => store.delete(key),
}

// Seed a custom palette with translucent panels plus two quick-launch chips, so
// the alpha maths, the brand colours and the dock all have something to render.
store.set(
  'fresh-green-skin:state',
  JSON.stringify({
    source: { kind: 'preset', id: 'meadow' },
    veil: 0.3,
    palette: 'custom',
    brandTint: true,
    topbarClear: true,
    colors: { brand: '', sidebar: '#2e8b57', bubble: '#2e8b57', text: '', whale: '#123456', wordmark: '#654321' },
    alpha: { sidebar: 40, bubble: 55 },
    chips: {
      enabled: true,
      items: [
        { id: 'c1', label: '浏览器', text: '/browser ', color: '#2e8b57' },
        { id: 'c2', label: '文档', text: '/doc ' },
      ],
    },
    font: '',
  }),
)

// --- minimal react --------------------------------------------------------
const hookState = []
let hookIndex = 0
const react = {
  createElement(type, props, ...children) {
    return { type, props: props || {}, children }
  },
  useState(initial) {
    const index = hookIndex++
    if (!(index in hookState)) hookState[index] = typeof initial === 'function' ? initial() : initial
    const set = (next) => {
      hookState[index] = typeof next === 'function' ? next(hookState[index]) : next
    }
    return [hookState[index], set]
  },
  useEffect() {},
  useRef(value) {
    return { current: value === undefined ? null : value }
  },
}

const requireShim = (id) => {
  if (id === 'react' || id === 'react/jsx-runtime') return react
  throw new Error(`unexpected require(${id})`)
}

// --- fake host client -----------------------------------------------------
const registered = []
const tokenCalls = []
let moduleEntry = null

const window = {
  __ModuleLoader__: {
    load(entry) {
      moduleEntry = entry
    },
  },
  addEventListener() {},
  removeEventListener() {},
}

class FakeImage {
  constructor() {
    this.naturalWidth = 100
    this.naturalHeight = 100
    this.onload = null
    this.onerror = null
  }
  set src(value) {
    this._src = value
  }
  get src() {
    return this._src
  }
}

const sandbox = {
  window,
  document,
  localStorage,
  require: requireShim,
  console,
  Image: FakeImage,
  URL: { createObjectURL: () => 'blob:stub', revokeObjectURL() {} },
}
sandbox.globalThis = sandbox
vm.createContext(sandbox)
vm.runInContext(source, sandbox, { filename: 'client.js' })

check(moduleEntry && typeof moduleEntry.factory === 'function', 'bundle calls __ModuleLoader__.load with a factory')
check(moduleEntry.id === 'dsh-fresh-green-skin', 'module id is dsh-fresh-green-skin')

const exports_ = moduleEntry.factory(requireShim)
check(Array.isArray(exports_.inject), 'entry exposes inject list')
check(exports_.inject.includes('theme'), 'injects the theme service')
check(exports_.inject.includes('slots'), 'injects the slots service')

const ctx = {
  effect(fn) {
    const dispose = fn()
    return typeof dispose === 'function' ? dispose : () => {}
  },
  theme: {
    overrideTokens(source, tokens) {
      tokenCalls.push({ source, tokens })
      return () => {}
    },
  },
  slots: {
    inject(name, register) {
      registered.push({ name, result: register() })
    },
    register(definition, component) {
      registered.push({ definition, component })
      return () => {}
    },
  },
}

try {
  exports_.apply(ctx)
} catch (error) {
  failures.push(`apply() threw: ${error.message}`)
  console.log(`FAIL apply() threw: ${error.message}`)
}

check(styleNodes.length === 1, 'injects exactly one <style> element')
check(document.body.dataset.freshSkin === 'on', 'marks the body with data-fresh-skin')
check(cssVars.has('--fgw-image'), 'sets --fgw-image')
check(cssVars.has('--fgw-veil'), 'sets --fgw-veil')
check(tokenCalls.length === 1, 'calls theme.overrideTokens once')
check(tokenCalls[0] && Object.keys(tokenCalls[0].tokens).length >= 15, 'overrides at least 15 theme tokens')
check(
  tokenCalls[0] && tokenCalls[0].tokens['--dsw-specific-sidebar-fill'] &&
    tokenCalls[0].tokens['--dsw-specific-sidebar-fill'].light === 'rgba(0,0,0,0)',
  'frame token is transparent so the wallpaper shows',
)

const row = registered.find((item) => item.definition && item.definition.id === 'fresh-green-wallpaper')
check(Boolean(row), 'registers the wallpaper row on settings.general.item')
check(row && row.definition.name === 'settings.general.item', 'row is registered in settings.general.item')
check(row && row.definition.order === 20, 'row order is 20')

// --- render the row once --------------------------------------------------
check(Boolean(row && typeof row.component === 'function'), 'row component is a function')

let tree = null
try {
  hookIndex = 0
  tree = row.component({})
} catch (error) {
  failures.push(`row render threw: ${error.message}`)
  console.log(`FAIL row render threw: ${error.stack.split('\n')[0]}`)
}

const text = (node, out = []) => {
  if (node === null || node === undefined || node === false) return out
  if (typeof node === 'string' || typeof node === 'number') {
    out.push(String(node))
    return out
  }
  if (Array.isArray(node)) {
    node.forEach((child) => text(child, out))
    return out
  }
  if (node.children) node.children.forEach((child) => text(child, out))
  return out
}

const nodes = (node, out = []) => {
  if (!node || typeof node !== 'object') return out
  if (Array.isArray(node)) {
    node.forEach((child) => nodes(child, out))
    return out
  }
  out.push(node)
  if (node.children) node.children.forEach((child) => nodes(child, out))
  return out
}

if (tree) {
  const rendered = text(tree).join(' ')
  check(rendered.includes('壁纸'), 'row renders the 壁纸 label')
  check(rendered.includes('透明度'), 'row renders the 透明度 slider label')
  check(/\d+%/.test(rendered), 'row renders a percentage value')
  check(rendered.includes('上传图片'), 'row renders the upload button')
  check(rendered.includes('上传视频'), 'row renders the video upload button')
  check(rendered.includes('恢复默认'), 'row renders the reset button')
  check(rendered.includes('跟随壁纸自动'), 'row renders the adaptive veil toggle')
  check(rendered.includes('跟随壁纸'), 'row renders the wallpaper-derived palette option')
  check(rendered.includes('保存主题'), 'row renders the save-theme button')
  check(rendered.includes('字体'), 'row renders the font picker')
  check(!rendered.includes('选一张自己的图片做背景'), 'row drops the old description sentence')

  const chips = nodes(tree).filter((node) => {
    const className = node.props && node.props.className
    return typeof className === 'string' && className.split(/\s+/).includes('fgw-chip')
  })
  const photoChips = chips.filter((chip) => !String(chip.props.className).split(/\s+/).includes('video'))
  check(photoChips.length >= 1, `row renders the preset gallery (${photoChips.length} photo chips)`)
  check(chips.length > photoChips.length, 'row renders a video chip')
  check(chips.filter((chip) => chip.props.className.includes('active')).length === 1, 'exactly one chip is active')
  check(
    photoChips.every((chip) => /^(url|linear-gradient|radial-gradient)\(/.test(String(chip.props.style.backgroundImage))),
    'every preset has a usable background-image',
  )
  check(
    photoChips.some((chip) => String(chip.props.style.backgroundImage).includes('data:image/')),
    'the default preset is an inlined photo',
  )
  check(rendered.includes('透光'), 'row renders the panel-translucency label')
  check(rendered.includes('品牌'), 'row renders the brand-colour line')
  check(rendered.includes('快捷条'), 'row renders the quick-launch line')
  check(rendered.includes('在输入框上方显示'), 'row renders the quick-launch toggle')
  check(rendered.includes('取色'), 'row renders eyedropper buttons')
  check(
    nodes(tree).some((node) => node.props.type === 'color' && node.props.value === '#123456'),
    'brand whale colour is rendered from state',
  )
  check(
    nodes(tree).some((node) => node.props.placeholder === '点图标时插入的文字'),
    'quick-launch editors are rendered',
  )
}

// --- translucency + brand tokens -----------------------------------------
check(String(cssVars.get('--fgw-sidebar') || '').startsWith('rgba(46,139,87'), 'sidebar colour is translucent')
check(cssVars.get('--fgw-whale') === '#123456', 'whale colour variable is set')
check(cssVars.get('--fgw-brandtext') === '#654321', 'brand text colour variable is set')
check(cssVars.get('--fgw-topbar') === 'transparent', 'topbar can be made clear')
const bubbleToken = tokenCalls[0] && tokenCalls[0].tokens['--dsw-alias-bg-layer-2']
check(
  Boolean(bubbleToken) && /^rgba\(46,139,87,0\.55\)$/.test(bubbleToken.light),
  'bubble colour honours its own opacity',
)
check(
  Boolean(tokenCalls[0]) && String(tokenCalls[0].tokens['--dsw-alias-bg-layer-2'].light) !== bubbleToken.light.replace('0.55', '1'),
  'bubbles are never fully opaque by default',
)
const CSS_TEXT = styleNodes.map((node) => node.textContent || '').join('\n')
check(CSS_TEXT.includes('canvas[data-home-whale]'), 'whale canvas is tinted by CSS')
check(CSS_TEXT.includes('_sidebarCol'), 'sidebar keeps a stable class hook')

// --- quick-launch dock ----------------------------------------------------
const dock = registered.find((item) => item.definition && item.definition.id === 'fresh-green-chips')
check(Boolean(dock), 'registers the quick-launch dock')
check(dock && dock.definition.name === 'conversation.input.dock', 'dock is registered on conversation.input.dock')
check(dock && dock.definition.order === 5, 'dock order is 5')
check(Boolean(dock && typeof dock.component === 'function'), 'dock component is a function')

if (dock && typeof dock.component === 'function') {
  let dockTree = null
  try {
    hookIndex = 0
    dockTree = dock.component({})
  } catch (error) {
    failures.push(`dock render threw: ${error.message}`)
    console.log(`FAIL dock render threw: ${error.message}`)
  }
  if (dockTree) {
    const buttons = nodes(dockTree).filter((node) => node.type === 'button')
    check(buttons.length === 2, `dock renders one chip per item (${buttons.length})`)
    check(
      nodes(dockTree).some((node) => node.props.className === 'fgw-dock-mark'),
      'chips show a first-letter mark',
    )
    check(
      nodes(dockTree).some(
        (node) => node.props.className === 'fgw-dock-mark' && String(node.props.style.background).startsWith('#'),
      ),
      'chip marks are coloured',
    )
  }
}

// --- 1.7 UX additions -----------------------------------------------------
if (tree) {
  const rendered = text(tree).join(' ')
  check(rendered.includes('一键预设'), 'row renders the one-click presets')
  check(rendered.includes('纯纸面'), 'presets include a plain-paper look')
  check(rendered.includes('纸面'), 'colours expose the paper anchor')
  check(rendered.includes('导出') && rendered.includes('导入'), 'themes can be exported and imported')
  check(rendered.includes('上传图标'), 'a custom logo can be uploaded')
  check(rendered.includes('隐藏大鲸鱼'), 'the hero whale can be hidden')

  const presets = nodes(tree).filter((node) => {
    const className = node.props && node.props.className
    return typeof className === 'string' && className.split(/\s+/).includes('fgw-preset')
  })
  check(presets.length === 4, `row renders four quick presets (${presets.length})`)
}

check(CSS_TEXT.includes('.fgw-preset'), 'preset buttons are styled')
check(CSS_TEXT.includes("body[data-fgw-logo='on']"), 'a custom logo hides the host whale')

// --- persistence keeps every panel field ----------------------------------
let saved = null
try {
  saved = JSON.parse(localStorage.getItem('fresh-green-skin:state') || 'null')
} catch {
  saved = null
}
check(Boolean(saved), 'state is written to localStorage')
check(Boolean(saved && saved.alpha && saved.alpha.sidebar === 40), 'sidebar opacity survives a reload')
check(Boolean(saved && saved.chips && Array.isArray(saved.chips.items)), 'quick-launch chips survive a reload')
check(Boolean(saved && typeof saved.topbarClear === 'boolean'), 'topbar flag survives a reload')

if (failures.length) {
  console.log(`\n${failures.length} check(s) failed`)
  process.exit(1)
}

console.log('\nall checks passed')