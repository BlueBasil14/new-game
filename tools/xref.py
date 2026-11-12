#!/usr/bin/env python3
"""Static cross-module check: every `Alias.member` used on a required project module must be
defined in that module. Catches contract mismatches that a compile-only check cannot."""
import re, sys, pathlib
root = pathlib.Path(__file__).resolve().parent.parent / "src"
files = {p.name.split(".")[0]: p for p in root.rglob("*.luau")}
defs = {}
for name, p in files.items():
    s = p.read_text()
    m = re.search(r"return\s+(\w+)\s*$", s.strip())
    tbl = m.group(1) if m else name
    d = set(re.findall(rf"function\s+{tbl}[.:](\w+)", s)) | set(re.findall(rf"^{tbl}\.(\w+)\s*=", s, re.M))
    # fields declared in the table constructor: local T = { a = ..., b = ... }
    c = re.search(rf"local\s+{tbl}(?::[^=]+)?=\s*\{{(.*?)^\}}", s, re.S | re.M)
    if c: d |= set(re.findall(r"^\t(\w+)\s*=", c.group(1), re.M))
    d |= set(re.findall(r"^export type (\w+)", s, re.M))
    defs[name] = d
bad = 0
for name, p in sorted(files.items()):
    s = re.sub(r"--\[\[.*?\]\]", "", p.read_text(), flags=re.S)
    s = re.sub(r"--[^\n]*", "", s)
    for alias, mod in re.findall(r"local\s+(\w+)\s*=\s*require\([^)]*?[.\"(](\w+)\"?\)*\)", s):
        if mod not in defs: continue
        for member in sorted(set(re.findall(rf"(?<![\w.]){alias}[.:](\w+)", s))):
            if member not in defs[mod]:
                bad += 1; print(f"{p.relative_to(root)}: {alias}.{member} not defined in {mod}")
print(f"xref: {bad} unresolved")
sys.exit(1 if bad else 0)
