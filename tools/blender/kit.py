# Shared helpers for biome prop kits. Run inside Blender via the Blender MCP:
#   exec(open(r"C:/Users/coolb/new game/new-game/tools/blender/kit.py").read())
# Units: 1 Blender unit = 1 Roblox stud. One grid cell = 4 studs. Z is up; props sit on z = 0.
import bpy, bmesh, math, os

ROOT = r"C:/Users/coolb/new game/new-game/assets/biomes"
GROUND = {"woodland": "#A3CF62"}  # turf colour each biome paints, used under renders


def hex_rgb(h):
    h = h.lstrip("#")
    srgb = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]


def mat(name, hexcol):
    """One flat colour material per palette entry. Name = palette key (becomes the Roblox part name)."""
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*hex_rgb(hexcol), 1)
    bsdf.inputs["Roughness"].default_value = 0.9
    m.diffuse_color = (*hex_rgb(hexcol), 1)
    return m


def setup_scene():
    """Empty scene with a turf-grey ground, neutral sun, orthographic-ish camera. Safe to call again."""
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE"
    sc.render.resolution_x = sc.render.resolution_y = 768
    sc.render.film_transparent = False
    w = sc.world or bpy.data.worlds.new("World")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (*hex_rgb("#B4B5B8"), 1)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
    sun.data.energy = 3
    sun.rotation_euler = (math.radians(50), 0, math.radians(35))
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam


def flat(obj):
    """Faceted low-poly look: flat shading, no smoothing."""
    for p in obj.data.polygons:
        p.use_smooth = False


def part(prop, part_name, mesh_obj, material):
    """Parent a mesh under the prop empty and name it <prop>__<part>; one material per part."""
    mesh_obj.name = f"{prop.name}__{part_name}"
    mesh_obj.data.materials.clear()
    mesh_obj.data.materials.append(material)
    mesh_obj.parent = prop
    flat(mesh_obj)
    return mesh_obj


def new_prop(name):
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
    return e


def tris(prop):
    n = 0
    for c in prop.children:
        dg = c.evaluated_get(bpy.context.evaluated_depsgraph_get())
        n += sum(len(p.vertices) - 2 for p in dg.data.polygons)
    return n


def bounds(prop):
    xs, ys, zs = [], [], []
    for c in prop.children:
        for v in c.bound_box:
            w = c.matrix_world @ __import__("mathutils").Vector(v)
            xs.append(w.x); ys.append(w.y); zs.append(w.z)
    return {"x": round(max(xs) - min(xs), 2), "y": round(max(ys) - min(ys), 2), "z": round(max(zs) - min(zs), 2), "zmin": round(min(zs), 2)}


def _only(prop):
    keep = {prop.name} | {c.name for c in prop.children}
    hidden = []
    for o in bpy.context.scene.objects:
        if o.type in {"MESH", "EMPTY"} and o.name not in keep and not o.hide_render:
            o.hide_render = True
            hidden.append(o)
    return hidden


def render(prop, biome):
    """Render the prop alone, 3/4 view framed to its size, to assets/biomes/<biome>/renders/<prop>.png."""
    b = bounds(prop)
    size = max(b["x"], b["y"], b["z"], 1)
    cam = bpy.context.scene.camera
    d = size * 2.2
    cam.location = (d * 0.75, -d * 0.75, b["z"] * 0.5 + d * 0.55)
    tgt = (0, 0, b["z"] * 0.45)
    dx, dy, dz = tgt[0] - cam.location[0], tgt[1] - cam.location[1], tgt[2] - cam.location[2]
    cam.rotation_euler = (math.atan2(math.hypot(dx, dy), -dz), 0, math.atan2(dy, dx) - math.pi / 2)
    hidden = _only(prop)
    # turf patch under the prop: one 4-stud cell grid in the biome's ground colour, for scale
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=1, y_subdivisions=1, size=max(8, math.ceil(size * 3 / 4) * 4))
    ground = bpy.context.active_object
    ground.data.materials.append(mat("_ground", GROUND.get(biome, "#B4B5B8")))
    out = os.path.join(ROOT, biome, "renders", prop.name + ".png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.context.scene.render.filepath = out
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(ground, do_unlink=True)
    for o in hidden:
        o.hide_render = False
    return out


def export(prop, biome):
    """FBX of the prop and its parts to assets/biomes/<biome>/fbx/<prop>.fbx (1 unit = 1 stud)."""
    bpy.ops.object.select_all(action="DESELECT")
    prop.select_set(True)
    for c in prop.children:
        c.select_set(True)
    out = os.path.join(ROOT, biome, "fbx", prop.name + ".fbx")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=out, use_selection=True, object_types={"EMPTY", "MESH"},
                             apply_unit_scale=True, bake_space_transform=True, mesh_smooth_type="FACE",
                             axis_forward="-Z", axis_up="Y")
    return out


def report(prop, biome):
    return {"prop": prop.name, "tris": tris(prop), "bounds": bounds(prop),
            "parts": [c.name for c in prop.children], "render": render(prop, biome), "fbx": export(prop, biome)}
