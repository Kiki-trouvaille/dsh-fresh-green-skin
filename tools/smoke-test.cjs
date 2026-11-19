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

  const chips = nodes(tree).filter(
    (node) => typeof node.props.className === 'string' && node.props.className.includes('fgw-chip'),
  )
  const photoChips = chips.filter((chip) => !chip.props.className.includes('video'))
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
}

if (failures.length) {
  console.log(`\n${failures.length} check(s) failed`)
  process.exit(1)
}

console.log('\nall checks passed')
