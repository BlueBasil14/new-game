// Headless server playtest. Usage:
//   node tools/luau/headless.mjs [-v] [nameFilter ...]
// Builds one Luau bundle per scenario: tools/luau/mock/roblox.luau + every module under
// src/shared and src/server wrapped as loader functions keyed by their Roblox path (layout of
// tools/build_place.py) + tests/headless/<scenario>.luau, runs it in the luau-web VM in a single
// call (Luau cannot re-enter JS), prints PASS/FAIL with a module:line map. Exit 1 on any failure.
// See docs/HEADLESS.md.
import { LuauState } from 'luau-web'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const walk = (d) => fs.existsSync(d) ? fs.readdirSync(d, { withFileTypes: true }).flatMap((e) =>
  e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]) : []

const args = process.argv.slice(2)
const verbose = args.includes('-v')
const filters = args.filter((a) => a !== '-v')

const ranges = [] // { start, end, name }
let bundle = ''
let line = 1
const add = (text, name) => {
  const n = text.split('\n').length
  if (name) ranges.push({ start: line, end: line + n - 1, name })
  bundle += text + '\n'
  line += n
}

const mockSrc = fs.readFileSync(path.join(root, 'tools/luau/mock/roblox.luau'), 'utf8')
add('local __M = (function()')
add(mockSrc, 'mock/roblox.luau')
add('end)()')
add(`__M.verbose = ${verbose}`)
add('local __MODS = {}')

function robloxPath(file) {
  const rel = path.relative(path.join(root, 'src'), file).split(path.sep)
  const top = rel.shift()
  const base = { shared: ['ReplicatedStorage', 'Shared'], server: ['ServerScriptService', 'Server'] }[top]
  const fname = rel.pop()
  const kind = fname.endsWith('.server.luau') ? 'Script' : 'ModuleScript'
  const name = fname.replace(/\.server\.luau$|\.luau$/, '')
  return { key: [...base, ...rel, name].join('.'), kind, name }
}
for (const dir of ['shared', 'server']) {
  for (const f of walk(path.join(root, 'src', dir)).filter((f) => f.endsWith('.luau')).sort()) {
    const { key, kind } = robloxPath(f)
    add(`__MODS[${JSON.stringify(key)}] = { kind = ${JSON.stringify(kind)}, fn = function(script)`)
    add(fs.readFileSync(f, 'utf8'), path.relative(root, f))
    add('end }')
  }
}
const prelude = bundle
const preludeRanges = [...ranges]
const preludeLine = line

const mapLines = (text) => text.replace(/\[string "([^"]+)"\]:(\d+)/g, (m, chunk, n) => {
  const ln = Number(n)
  const r = ranges.find((r) => ln >= r.start && ln <= r.end)
  return r ? `${r.name}:${ln - r.start + 1}` : m
})

const scenarios = walk(path.join(root, 'tests/headless')).filter((f) => f.endsWith('.luau')).sort()
  .filter((f) => filters.length === 0 || filters.some((w) => path.basename(f).includes(w)))
let failed = 0
for (const f of scenarios) {
  const name = path.basename(f, '.luau')
  bundle = prelude
  ranges.length = 0
  ranges.push(...preludeRanges)
  line = preludeLine
  add('local __SCENARIO = function(H)')
  add(fs.readFileSync(f, 'utf8'), `tests/headless/${name}.luau`)
  add('end')
  add(`return __M.runScenario(__MODS, __SCENARIO, ${JSON.stringify(name)})`)
  const t0 = Date.now()
  let out
  try {
    const state = await LuauState.createAsync()
    const fn = state.loadstring(bundle, 'B', true)
    const res = await fn()
    out = String(Array.isArray(res) ? res[0] : res)
  } catch (e) {
    out = 'FAIL\n' + (e && e.message ? e.message : String(e))
  }
  out = mapLines(out)
  const secs = ((Date.now() - t0) / 1000).toFixed(1)
  const [status, ...rest] = out.split('\n')
  if (status !== 'PASS') failed++
  console.log(`${status === 'PASS' ? 'PASS' : 'FAIL'} ${name} (${secs}s real)`)
  const body = rest.join('\n').trim()
  if (body) console.log('  ' + body.split('\n').join('\n  '))
}
console.log(`${scenarios.length - failed}/${scenarios.length} scenarios passed`)
process.exit(failed ? 1 : 0)
