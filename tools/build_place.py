#!/usr/bin/env python3
"""Build build/TurfLoop.rbxlx from src/ (stdlib only). Usage: build_place.py [--check]"""
import os, sys, tempfile, xml.etree.ElementTree as ET
from xml.sax.saxutils import escape

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "build", "TurfLoop.rbxlx")
_counter = [0]


class Node:
    def __init__(self, cls, name, props=None, source=None):
        _counter[0] += 1
        self.ref = "RBX%032X" % _counter[0]
        self.cls, self.name, self.props, self.source = cls, name, props or [], source
        self.children = []

    def add(self, c):
        self.children.append(c)
        return c

    def xml(self, out, ind=1):
        p = "\t" * ind
        out.append('%s<Item class="%s" referent="%s">' % (p, self.cls, self.ref))
        out.append("%s\t<Properties>" % p)
        out.append('%s\t\t<string name="Name">%s</string>' % (p, escape(self.name)))
        for kind, key, val in self.props:
            v = str(val).lower() if kind == "bool" else escape(str(val))
            out.append('%s\t\t<%s name="%s">%s</%s>' % (p, kind, key, v, kind))
        if self.source is not None:
            src = self.source.replace("]]>", "]]]]><![CDATA[>")
            out.append('%s\t\t<ProtectedString name="Source"><![CDATA[%s]]></ProtectedString>' % (p, src))
        out.append("%s\t</Properties>" % p)
        for c in self.children:
            c.xml(out, ind + 1)
        out.append("%s</Item>" % p)


def classify(fname):
    """Return (kind, name) for a .luau file name."""
    if fname.endswith(".server.luau"):
        return "Script", fname[: -len(".server.luau")]
    if fname.endswith(".client.luau"):
        return "LocalScript", fname[: -len(".client.luau")]
    return "ModuleScript", fname[: -len(".luau")]


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


INITS = {"init.luau": "ModuleScript", "init.server.luau": "Script", "init.client.luau": "LocalScript"}


def build_dir(path, name, emitted):
    entries = sorted(os.listdir(path))
    init = next((e for e in entries if e in INITS and os.path.isfile(os.path.join(path, e))), None)
    if init:
        ip = os.path.join(path, init)
        node = Node(INITS[init], name, source=read(ip))
        emitted.append(ip)
    else:
        node = Node("Folder", name)
    for e in entries:
        full = os.path.join(path, e)
        if e == init or e.startswith("."):
            continue
        if os.path.isdir(full):
            node.add(build_dir(full, e, emitted))
        elif e.endswith(".luau"):
            kind, nm = classify(e)
            node.add(Node(kind, nm, source=read(full)))
            emitted.append(full)
    return node


def build(out_path):
    emitted = []
    shared = build_dir(os.path.join(SRC, "shared"), "Shared", emitted) if os.path.isdir(os.path.join(SRC, "shared")) else Node("Folder", "Shared")
    server = build_dir(os.path.join(SRC, "server"), "Server", emitted) if os.path.isdir(os.path.join(SRC, "server")) else Node("Folder", "Server")
    client = build_dir(os.path.join(SRC, "client"), "Client", emitted) if os.path.isdir(os.path.join(SRC, "client")) else Node("Folder", "Client")

    ws = Node("Workspace", "Workspace", [("bool", "FilteringEnabled", True), ("bool", "StreamingEnabled", False)])
    lighting = Node("Lighting", "Lighting")
    rs = Node("ReplicatedStorage", "ReplicatedStorage")
    rs.add(shared)
    sss = Node("ServerScriptService", "ServerScriptService")
    sss.add(server)
    sp = Node("StarterPlayer", "StarterPlayer")
    sps = sp.add(Node("StarterPlayerScripts", "StarterPlayerScripts"))
    sps.add(client)
    sp.add(Node("StarterCharacterScripts", "StarterCharacterScripts"))
    roots = [ws, lighting, rs, sss, Node("ServerStorage", "ServerStorage"), Node("StarterGui", "StarterGui"),
             Node("StarterPack", "StarterPack"), sp, Node("SoundService", "SoundService"),
             Node("Players", "Players", [("bool", "CharacterAutoLoads", True)])]

    out = ['<?xml version="1.0" encoding="utf-8"?>',
           '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">']
    for r in roots:
        r.xml(out)
    out.append("</roblox>")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")

    # Preserve the authored Sound System assets and boot scripts on every rebuild.
    vendor_dir = os.path.join(ROOT, "assets", "rblxessentials")
    vendor_scripts = 0
    if os.path.isdir(vendor_dir):
        document = ET.parse(out_path)
        place_root = document.getroot()
        def named_child(parent, name):
            return next(item for item in parent.findall("Item")
                        if item.findtext("Properties/string[@name='Name']") == name)
        for filename in sorted(os.listdir(vendor_dir)):
            if not filename.endswith(".rbxmx"):
                continue
            service = filename[:-6]
            target = (named_child(named_child(place_root, "StarterPlayer"), "StarterPlayerScripts")
                      if service == "StarterPlayerScripts" else named_child(place_root, service))
            for item in ET.parse(os.path.join(vendor_dir, filename)).getroot().findall("Item"):
                vendor_scripts += sum(child.get("class") in ("Script", "LocalScript", "ModuleScript")
                                      for child in item.iter("Item"))
                target.append(item)
        document.write(out_path, encoding="utf-8", xml_declaration=True)

    # verify well-formed + unique referents
    tree = ET.parse(out_path)
    items = list(tree.getroot().iter("Item"))
    refs = [i.get("referent") for i in items]
    ok = len(refs) == len(set(refs))
    counts = {k: 0 for k in ("Script", "LocalScript", "ModuleScript", "Folder")}
    for i in items:
        if i.get("class") in counts:
            counts[i.get("class")] += 1
    # every src .luau emitted exactly once
    expected = sorted(os.path.join(d, f) for d, _, fs in os.walk(SRC) for f in fs
                      if f.endswith(".luau") and not any(p.startswith(".") for p in os.path.relpath(d, SRC).split(os.sep)))
    bad = [p for p in expected if emitted.count(p) != 1]
    n_scripts = counts["Script"] + counts["LocalScript"] + counts["ModuleScript"]
    if n_scripts != len(expected) + vendor_scripts:
        bad.append("script count %d != src files %d + vendor scripts %d"
                   % (n_scripts, len(expected), vendor_scripts))
    size = os.path.getsize(out_path)
    print("%s: Script=%d LocalScript=%d ModuleScript=%d Folder=%d, src files=%d, %d bytes"
          % (os.path.relpath(out_path, ROOT), counts["Script"], counts["LocalScript"],
             counts["ModuleScript"], counts["Folder"], len(expected), size))
    if not ok:
        print("ERROR: duplicate referents", file=sys.stderr)
    for b in bad:
        print("ERROR: not emitted exactly once: %s" % b, file=sys.stderr)
    return ok and not bad


def main():
    if "--check" in sys.argv[1:]:
        with tempfile.TemporaryDirectory() as td:
            good = build(os.path.join(td, "check.rbxlx"))
        print("check OK" if good else "check FAILED")
    else:
        good = build(OUT)
    return 0 if good else 1


if __name__ == "__main__":
    sys.exit(main())
