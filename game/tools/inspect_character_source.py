"""Inspect the CC0 Quaternius source without altering downloaded originals."""
import bpy, pathlib, json
SOURCE=pathlib.Path(r'D:\python_workplace\InternalNCrush\.tools\quaternius-base\Universal Base Characters[Standard]\Base Characters\Godot - UE')
for sex in ['Female','Male']:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE/f'Superhero_{sex}_FullBody.gltf'))
    print('CHARACTER',sex)
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':
            obj.data.calc_loop_triangles()
            print('MESH',obj.name,len(obj.data.loop_triangles),list(obj.dimensions),[m.name for m in obj.data.materials])
        if obj.type=='ARMATURE':
            print('BONES',json.dumps({b.name:[list(b.head_local),list(b.tail_local)] for b in obj.data.bones}))
