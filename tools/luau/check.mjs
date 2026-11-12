// Compile-checks every .luau file under src/ with the real Luau compiler (WASM),
// then runs tests/*.spec.luau against the pure modules in src/shared.
// Usage: node tools/luau/check.mjs [--no-tests]
import { LuauState } from 'luau-web'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..')
const walk = (d) => fs.existsSync(d) ? fs.readdirSync(d, { withFileTypes: true }).flatMap((e) =>
  e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]) : []

let failed = 0
const state = await LuauState.createAsync()

// 1. syntax / compile check
const files = walk(path.join(root, 'src')).filter((f) => f.endsWith('.luau'))
for (const f of files) {
  const res = state.loadstring(fs.readFileSync(f, 'utf8'), path.relative(root, f), false)
  if (typeof res === 'string') { failed++; console.log('COMPILE FAIL ' + res) }
}
console.log(`compiled ${files.length} files, ${failed} failed`)

// 2. unit tests for pure shared modules. Luau cannot re-enter JS for require, so each
// test runs as one bundle: every src/shared module wrapped in a loader function, then the test.
// Error line numbers are bundle lines; the "line map" printed on failure converts them.
if (!process.argv.includes('--no-tests')) {
  const shared = walk(path.join(root, 'src/shared')).filter((f) => f.endsWith('.luau'))
  let bundle = 'local __mods, __cache = {}, {}\n' +
    'local script = { Parent = setmetatable({}, { __index = function(_, k) return { __module = k } end }) }\n' +
    'local function require(tok) local n = tok.__module; if __cache[n] == nil then local f = __mods[n]; if not f then error("no shared module " .. tostring(n)) end; __cache[n] = f() end; return __cache[n] end\n'
  const map = []
  let line = 4
  for (const f of shared) {
    const src = fs.readFileSync(f, 'utf8')
    const name = path.basename(f, '.luau')
    map.push(`${name}@${line + 1}`)
    bundle += `__mods[${JSON.stringify(name)}] = function()\n${src}\nend\n`
    line += src.split('\n').length + 2
  }
  for (const f of walk(path.join(root, 'tests')).filter((f) => f.endsWith('.spec.luau'))) {
    try {
      const out = await state.loadstring(bundle + fs.readFileSync(f, 'utf8'), path.basename(f), true)()
      console.log(`PASS ${path.basename(f)} ${out ?? ''}`)
    } catch (e) {
      failed++
      console.log(`TEST FAIL ${path.basename(f)}: ${e.message}\n  line map: ${map.join(' ')} test@${line + 1}`)
    }
  }
}
process.exit(failed ? 1 : 0)
