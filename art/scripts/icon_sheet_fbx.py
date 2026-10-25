"""Builds a flat plane textured with the item icon sheet and exports it as an FBX, so
Studio's 3D importer uploads the sheet as an Image asset (transparency kept). Used when the
Asset Manager's image import isn't available; see art/README.md.
Run:
  blender --background --factory-startup --python art/scripts/icon_sheet_fbx.py -- art/textures/item_icons.png art/export/IconSheet.fbx
"""

import sys

import bpy

sheet, out = sys.argv[sys.argv.index("--") + 1 :][:2]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.mesh.primitive_plane_add(size=2)
plane = bpy.context.active_object
plane.name = "ItemIconSheet"

material = bpy.data.materials.new("ItemIconSheet")
material.use_nodes = True
nodes = material.node_tree.nodes
bsdf = nodes["Principled BSDF"]
texture = nodes.new("ShaderNodeTexImage")
texture.image = bpy.data.images.load(sheet)
material.node_tree.links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
material.node_tree.links.new(texture.outputs["Alpha"], bsdf.inputs["Alpha"])
plane.data.materials.append(material)

bpy.ops.export_scene.fbx(
    filepath=out,
    use_selection=False,
    object_types={"MESH"},
    path_mode="COPY",
    embed_textures=True,
)
print("exported", out)
