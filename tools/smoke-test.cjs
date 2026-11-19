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

const document = {
  head: { appendChild: (node) => styleNodes.push(node) },
  body: { dataset: bodyProps },
  createElement: () => ({ textContent: '', dataset: {}, remove() {} }),
  documentElement: { dataset: {}, style: { setProperty() {} } },
  querySelector: () => null,
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
}

const sandbox = { window, document, localStorage, require: requireShim, console }
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
check(bodyProps.freshSkin === 'on', 'marks the body with data-fresh-skin')
check(tokenCalls.length === 1, 'calls theme.overrideTokens once')
check(tokenCalls[0] && Object.keys(tokenCalls[0].tokens).length >= 15, 'overrides at least 15 theme tokens')

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

if (tree) {
  const rendered = text(tree).join(' ')
  check(rendered.includes('壁纸'), 'row renders the 壁纸 label')
  check(rendered.includes('透明度'), 'row renders the 透明度 slider label')
  check(/\d+%/.test(rendered), 'row renders a percentage value')
  check(rendered.includes('上传图片'), 'row renders the upload button')
  check(rendered.includes('恢复默认'), 'row renders the reset button')
}

if (failures.length) {
  console.log(`\n${failures.length} check(s) failed`)
  process.exit(1)
}

console.log('\nall checks passed')
