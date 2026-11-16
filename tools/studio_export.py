#!/usr/bin/env python3
"""Export the script folders from build/TurfLoop.rbxlx as a model Studio can load with
game:GetObjects("rbxasset://turfloop_sync.rbxmx"). See docs/STUDIO.md.

    py tools/studio_export.py            # Shared, Server, Client
    py tools/studio_export.py --sounds   # also SoundService.RBLXEssentials (first load of an empty place)
    py tools/studio_export.py --clean    # delete the exported file again
"""
import glob
import os
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAME = "turfloop_sync.rbxmx"


def content_dirs():
    for d in glob.glob(os.path.expandvars(r"%LOCALAPPDATA%\Roblox\Versions\*")):
        if os.path.exists(os.path.join(d, "RobloxStudioBeta.exe")):
            yield os.path.join(d, "content")


def name_of(item):
    return item.findtext("Properties/string[@name='Name']")


def main():
    if "--clean" in sys.argv:
        for d in content_dirs():
            path = os.path.join(d, NAME)
            if os.path.exists(path):
                os.remove(path)
                print("removed", path)
        return
    root = ET.parse(os.path.join(ROOT, "build", "TurfLoop.rbxlx")).getroot()
    want = {}

    def walk(item, path):
        for child in item.findall("Item"):
            p = path + [name_of(child) or child.get("class")]
            key = None
            if child.get("class") == "Folder" and len(p) <= 3:
                if p[-1] in ("Shared", "Server", "Client"):
                    key = p[-1]
                elif p[-1] == "RBLXEssentials" and "SoundService" in p:
                    key = "RBLXEssentials"
            if key:
                want[key] = child
            else:
                walk(child, p)

    walk(root, [])
    keys = ["Shared", "Server", "Client"] + (["RBLXEssentials"] if "--sounds" in sys.argv else [])
    out = ET.Element("roblox", {"version": "4"})
    for k in keys:
        out.append(want[k])
    wrote = False
    for d in content_dirs():
        path = os.path.join(d, NAME)
        ET.ElementTree(out).write(path, encoding="utf-8", xml_declaration=True)
        print("wrote", path, os.path.getsize(path), "bytes:", ", ".join(keys))
        wrote = True
    if not wrote:
        sys.exit("no Roblox Studio install found under %LOCALAPPDATA%\\Roblox\\Versions")


if __name__ == "__main__":
    main()
