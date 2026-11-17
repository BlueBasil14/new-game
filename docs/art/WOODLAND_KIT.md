# Living Woodland prop kit (biome skin prototype)

Owner direction (2026-11-16): captured land itself becomes the cosmetic. Biome skins paint the turf and
grow low-poly scenery across it. Woodland is the first prototype; judge it in Studio before other biomes.

## Look
- Low-poly, faceted (flat shading), chunky and readable from the game camera (~60 studs up, looking down).
  Think toy diorama: few big facets, slightly exaggerated shapes, no thin detail that turns into noise.
- Solid colours only. No textures, no UVs needed. One material per colour, named by the palette key.
- Silhouette first: every prop must be recognisable from above at 3/4 angle.
- Slight variety via vertex jitter and rotation, but keep facets clean (no slivers, no inverted normals).

## Palette (material name = key)
| key | hex | use |
|---|---|---|
| bark | #7A5236 | trunks, logs |
| bark_dark | #5C3D27 | log end rings, roots |
| wood_end | #C9A57A | cut log faces |
| leaf | #4FA34A | main canopy, bushes |
| leaf_light | #7CC35A | top canopy highlight blobs |
| leaf_dark | #2F7A3B | lower canopy layer, bush underside |
| rock | #8E949A | rocks |
| rock_dark | #6B7178 | rock base chunks |
| moss | #6BAA4A | moss caps on rocks/logs |
| cap_red | #E2533F | mushroom caps |
| stem | #F2E6CF | mushroom stems |
| spot | #FFFFFF | mushroom spots |

The turf under them is #A3CF62 (lightened after review so leaves separate). Canopies use leaf/leaf_light, never the turf green.

## Units and limits
- 1 Blender unit = 1 stud. One grid cell = 4 studs. Z up. Each prop sits on z = 0, centred on x = y = 0.
- Max **400 triangles per prop** (trees), 150 for small props. Fewer is better.
- At most **4 parts (materials) per prop**. Each part becomes one Roblox MeshPart.
- Every part must be closed and outward-facing. Nothing below z = -0.2.

## Props (names are exact)
| prop | footprint (studs) | height | notes |
|---|---|---|---|
| wood_rock_a | 2.5 | 1.2 | flat boulder, moss cap on top |
| wood_rock_b | 1.5 | 1.5 | taller chunky stone |
| wood_rock_c | 1.0 | 0.6 | small pebble cluster (3 pebbles, one part) |
| wood_log_a | 5 long x 1.4 | 1.4 | fallen log, cut ends in wood_end, moss patch |
| wood_log_b | 3.5 long x 1.0 | 1.0 | short log with a stubby branch |
| wood_bush_a | 3 | 2.2 | round 3-blob bush |
| wood_bush_b | 2.2 | 1.6 | low wide bush, a few leaf_light blobs |
| wood_tree_round | 6 canopy | 10 | round lumpy canopy (2-3 overlapping low-poly spheres) on a tapered trunk |
| wood_tree_pine | 5 base | 12 | stacked 3-tier cone pine, leaf_dark |
| wood_tree_tall | 5 canopy | 13 | tall oak, trunk splits into 2 boughs, 2 canopy clumps |
| wood_mushrooms | 2.5 | 1.6 | cluster of 3 red mushrooms of different heights, white spots |

Trees must fit inside a 2x2-cell (8 stud) square including canopy. Small props fit in one cell.

## How to build (Blender MCP, `execute_blender_code`)
```python
exec(open(r"C:/Users/coolb/new game/new-game/tools/blender/kit.py").read())
p = new_prop("wood_rock_a")
# build meshes with bpy.ops.mesh.primitive_* or bmesh, then for each:
part(p, "rock", obj, mat("rock", "#8E949A"))
result = report(p, "woodland")   # tris, bounds, render path, fbx path
```
- Do **not** call `setup_scene()` and never delete objects you did not create: another worker shares this Blender.
- Apply object transforms on parts before `report` (or build at final size) so the FBX is right.
- Read the render PNG after each prop and fix what reads badly before moving on. Iterate at least once per tree.
- Renders: `assets/biomes/woodland/renders/<prop>.png`. FBX: `assets/biomes/woodland/fbx/<prop>.fbx`.

## Growth animation (for reference; Roblox code does this, not Blender)
Parts are named `<prop>__<key>`. The game scales parts in this order: trunk/bark/rock/stem first, then
leaf_dark, leaf, leaf_light/cap/spot last, so canopies "open" after trunks grow. Keep that split clean.
