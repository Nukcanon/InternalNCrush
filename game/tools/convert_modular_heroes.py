"""Convert Quaternius Ultimate Modular Men/Women (CC0) characters for the game rig.

The glTF characters are T-posed, face +Z and use a 62-bone skeleton. The game
drives a 15-joint operator rig (arms hanging, facing -Z). For each outfit this
tool:
  1. re-poses the arm chains from T-pose to hanging arms with linear blend
     skinning (smooth weights, no seams),
  2. rotates to face -Z and scales so the head pivot matches the game rig,
  3. maps every source bone onto one of the 15 rig joints (weights summed),
  4. records rig joint offsets measured from the re-posed skeleton, and a hit
     profile (limb lengths/radii, head/torso ellipsoids) from the mesh itself,
  5. keeps each source material as a palette slot so teams can recolour it.
Output: game/assets/heroes/<outfit>.json (compact arrays).
Source files are not redistributed; only derived geometry is stored.
"""
import base64, json, math, struct, sys
from pathlib import Path
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT.parent / '.tools' / 'quaternius-modular'
OUT = ROOT / 'game' / 'assets' / 'heroes'
JOINTS = ["Hips", "Chest", "Head", "LeftArm", "LeftElbow", "LeftHand", "RightArm", "RightElbow", "RightHand",
          "LeftLeg", "LeftKnee", "LeftFoot", "RightLeg", "RightKnee", "RightFoot"]
PARENT = [-1, 0, 1, 1, 3, 4, 1, 6, 7, 0, 9, 10, 0, 12, 13]
HEAD_PIVOT_Y = 1.60  # game rig head joint height (1.8 m nominal operator)
ARM_DROP_DEG = 78.0  # arms rest slightly away from the body to avoid hip overlap


def bone_joint(name: str) -> int:
    side = 'Left' if name.endswith('.L') else 'Right' if name.endswith('.R') else ''
    base = name[:-2] if side else name
    if base in ('Root', 'Body', 'Hips', 'Abdomen'):
        return 0
    if base in ('Torso', 'Chest'):
        return 1
    if base in ('Neck', 'Head'):
        return 2
    table = {'Shoulder': 'Arm', 'UpperArm': 'Arm', 'LowerArm': 'Elbow', 'Wrist': 'Hand',
             'UpperLeg': 'Leg', 'LowerLeg': 'Knee', 'Foot': 'Foot', 'PT': 'Foot'}
    for prefix in ('Index', 'Middle', 'Ring', 'Pinky', 'Thumb'):
        if base.startswith(prefix):
            return JOINTS.index(side + 'Hand')
    return JOINTS.index(side + table[base])


def load(path: Path):
    g = json.loads(path.read_text(encoding='utf-8'))
    buffers = [base64.b64decode(b['uri'].split(',', 1)[1]) for b in g['buffers']]

    def accessor(i):
        a = g['accessors'][i]; view = g['bufferViews'][a['bufferView']]; raw = buffers[view['buffer']]
        fmt, size = {5126: ('f', 4), 5123: ('H', 2), 5125: ('I', 4), 5121: ('B', 1)}[a['componentType']]
        n = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
        start = view.get('byteOffset', 0) + a.get('byteOffset', 0); stride = view.get('byteStride', size * n)
        dt = np.dtype({'f': '<f4', 'H': '<u2', 'I': '<u4', 'B': 'u1'}[fmt])
        if stride == size * n:
            arr = np.frombuffer(raw, dtype=dt, count=a['count'] * n, offset=start).reshape(a['count'], n)
        else:
            arr = np.array([np.frombuffer(raw, dtype=dt, count=n, offset=start + k * stride) for k in range(a['count'])])
        arr = arr.astype(np.float64)
        if a.get('normalized') and fmt != 'f':
            arr /= {'H': 65535., 'B': 255.}[fmt]
        return arr
    return g, accessor


def convert(path: Path, outfit: str):
    g, accessor = load(path)
    skin = g['skins'][0]; joints = skin['joints']; names = [g['nodes'][j]['name'] for j in joints]
    inverse_bind = accessor(skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
    bind = np.linalg.inv(inverse_bind)
    pos_of = {n: bind[i][:3, 3] for i, n in enumerate(names)}
    # Re-pose: rotate each arm chain about its UpperArm pivot, down and slightly forward.
    rest = np.array([np.eye(4) for _ in names])
    for side, sign in (('L', 1.), ('R', -1.)):
        pivot = pos_of['UpperArm.' + side]; angle = math.radians(ARM_DROP_DEG) * -sign
        c, s = math.cos(angle), math.sin(angle)
        rot = np.array([[c, -s, 0, 0], [s, c, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
        move = np.eye(4); move[:3, 3] = pivot; back = np.eye(4); back[:3, 3] = -pivot
        chain = move @ rot @ back
        for i, n in enumerate(names):
            base = n[:-2] if n.endswith('.' + side) else None
            if base and base not in ('Shoulder',) and base not in ('UpperLeg', 'LowerLeg', 'Foot', 'PT'):
                rest[i] = chain
    positions = []; normals = []; slots = []; bones = []; weights = []; indices = []; palette = []
    material_names = []
    for mesh_node in [n for n in g['nodes'] if 'mesh' in n and 'skin' in n]:
        for prim in g['meshes'][mesh_node['mesh']]['primitives']:
            mat = g['materials'][prim['material']]; name = mat.get('name', 'Material')
            if name not in material_names:
                material_names.append(name)
                palette.append([round(float(x), 5) for x in mat.get('pbrMetallicRoughness', {}).get('baseColorFactor', [1, 1, 1, 1])[:3]])
            slot = material_names.index(name)
            p = accessor(prim['attributes']['POSITION']); nrm = accessor(prim['attributes']['NORMAL'])
            j = accessor(prim['attributes']['JOINTS_0']).astype(int); w = accessor(prim['attributes']['WEIGHTS_0'])
            w = w / np.maximum(w.sum(1, keepdims=True), 1e-9)
            # Linear blend skinning from bind to the re-posed rest.
            skin_m = np.einsum('vk,vkij->vij', w, (rest @ bind @ inverse_bind)[j] if False else rest[j])
            ph = np.concatenate([p, np.ones((len(p), 1))], 1)
            p2 = np.einsum('vij,vj->vi', skin_m, ph)[:, :3]
            n2 = np.einsum('vij,vj->vi', skin_m[:, :3, :3], nrm); n2 /= np.maximum(np.linalg.norm(n2, axis=1, keepdims=True), 1e-9)
            base = len(positions)
            positions.extend(p2); normals.extend(n2); slots.extend([slot] * len(p2))
            for vj, vw in zip(j, w):
                agg = {}
                for jj, ww in zip(vj, vw):
                    if ww > 0: agg[bone_joint(names[jj])] = agg.get(bone_joint(names[jj]), 0.) + ww
                top = sorted(agg.items(), key=lambda kv: -kv[1])[:4]
                total = sum(v for _, v in top) or 1.
                bones.append([k for k, _ in top] + [0] * (4 - len(top)))
                weights.append([v / total for _, v in top] + [0.] * (4 - len(top)))
            idx = accessor(prim['indices']).astype(int).ravel() + base
            indices.extend(idx.tolist())
    P = np.array(positions); N = np.array(normals)
    # Re-posed joint positions (rest transform applied to bind origins).
    joint_pos = {n: (rest[i] @ np.append(pos_of[n], 1.))[:3] for i, n in enumerate(names)}
    # Face -Z (rotate 180 deg about Y) and scale the head pivot to the game rig.
    flip = np.array([-1., 1., -1.])
    scale = HEAD_PIVOT_Y / joint_pos['Neck'][1]
    P = P * flip * scale; N = N * flip
    J = {k: v * flip * scale for k, v in joint_pos.items()}
    rig = {
        'Hips': J['Hips'], 'Chest': J['Torso'], 'Head': J['Neck'],
        'LeftArm': J['UpperArm.L'], 'LeftElbow': J['LowerArm.L'], 'LeftHand': J['Wrist.L'],
        'RightArm': J['UpperArm.R'], 'RightElbow': J['LowerArm.R'], 'RightHand': J['Wrist.R'],
        'LeftLeg': J['UpperLeg.L'], 'LeftKnee': J['LowerLeg.L'], 'LeftFoot': J['Foot.L'],
        'RightLeg': J['UpperLeg.R'], 'RightKnee': J['LowerLeg.R'], 'RightFoot': J['Foot.R']}
    offsets = {}
    for i, name in enumerate(JOINTS):
        parent = PARENT[i]
        offsets[name] = [round(float(x), 5) for x in (rig[name] - (rig[JOINTS[parent]] if parent >= 0 else 0.))]
    # Hit profile: limb capsules and body ellipsoids measured from dominant vertices.
    B = np.array(bones); W = np.array(weights)
    dominant = B[np.arange(len(B)), W.argmax(1)]
    profile = {}
    for limb, child in (('LeftArm', 'LeftElbow'), ('LeftElbow', 'LeftHand'), ('LeftLeg', 'LeftKnee'), ('LeftKnee', 'LeftFoot')):
        a = rig[limb]; b = rig[child]; axis = b - a; length = np.linalg.norm(axis)
        pts = P[dominant == JOINTS.index(limb)] - a
        t = np.clip(pts @ axis / length ** 2, 0, 1)
        radial = np.linalg.norm(pts - np.outer(t, axis), axis=1)
        profile[limb.replace('Left', '')] = [round(float(length), 4), round(float(np.percentile(radial, 70)) * .85, 4)]
    def ellipsoid(mask, origin):
        pts = P[mask] - origin
        lo = np.percentile(pts, 3, axis=0); hi = np.percentile(pts, 97, axis=0)
        return [round(float(x), 4) for x in ((lo + hi) / 2)] + [round(float(x), 4) for x in ((hi - lo) / 2 * .92)]
    profile['Head'] = ellipsoid(dominant == 2, rig['Head'])
    profile['Chest'] = ellipsoid(dominant == 1, rig['Chest'])
    profile['Hips'] = ellipsoid(dominant == 0, rig['Hips'])
    hand = P[dominant == JOINTS.index('LeftHand')] - rig['LeftHand']
    profile['Hand'] = [round(float(np.percentile(np.linalg.norm(hand, axis=1), 80)), 4)]
    profile['Height'] = round(float(P[:, 1].max()), 4)
    OUT.mkdir(parents=True, exist_ok=True)
    data = {
        'source': 'Quaternius Ultimate Modular ' + ('Women' if 'women' in str(path) else 'Men') + ' (CC0) - ' + path.stem,
        'joints': JOINTS, 'offsets': offsets, 'profile': profile,
        'materials': material_names, 'palette': palette,
        'vertices': np.round(P, 5).ravel().tolist(), 'normals': np.round(N, 4).ravel().tolist(),
        'slots': slots, 'bones': B.ravel().tolist(), 'weights': np.round(W, 4).ravel().tolist(),
        'indices': indices}
    (OUT / f'{outfit}.json').write_text(json.dumps(data, separators=(',', ':')), encoding='utf-8')
    print(f'{outfit}: {len(P)} vertices, {len(indices)//3} triangles, height {profile["Height"]} m, materials {material_names}')


if __name__ == '__main__':
    for spec in sys.argv[1:] or ['men/Swat', 'women/Soldier', 'men/Spacesuit', 'men/Worker', 'men/Adventurer', 'women/SciFi']:
        convert(SOURCE / (spec + '.gltf'), spec.replace('/', '_').lower())
