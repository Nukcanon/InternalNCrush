"""Clip planar 3D triangles before assigning material/culling tiles.

Centroid-only assignment lets a long triangle carry one district's material
across an entire room. Keep winding and interpolated elevation while splitting
at exact world-space X/Z boundaries, including vertical walls.
"""
import math


def clip(poly, axis, boundary, positive):
    result = []
    previous = poly[-1]
    prev_inside = previous[axis] >= boundary if positive else previous[axis] <= boundary
    for current in poly:
        inside = current[axis] >= boundary if positive else current[axis] <= boundary
        if inside != prev_inside:
            t = (boundary - previous[axis]) / (current[axis] - previous[axis])
            point = [previous[k] + t * (current[k] - previous[k]) for k in range(3)]
            point[axis] = boundary
            result.append(point)
        if inside:
            result.append(current)
        previous, prev_inside = current, inside
    return result


def tiled_triangles(points, origin_x, origin_z, size=24):
    ranges = []
    for axis, origin in [(0, origin_x), (2, origin_z)]:
        low = math.floor((min(p[axis] for p in points) - origin) / size)
        high = max(low, math.ceil((max(p[axis] for p in points) - origin) / size) - 1)
        ranges.append(range(low, high + 1))
    for x in ranges[0]:
        for z in ranges[1]:
            poly = points
            for axis, low in [(0, origin_x + x * size), (2, origin_z + z * size)]:
                for boundary, positive in [(low, True), (low + size, False)]:
                    if poly:
                        poly = clip(poly, axis, boundary, positive)
            for i in range(1, len(poly) - 1):
                tri = [poly[0], poly[i], poly[i + 1]]
                u = [tri[1][k] - tri[0][k] for k in range(3)]
                v = [tri[2][k] - tri[0][k] for k in range(3)]
                cross = [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]]
                if sum(n*n for n in cross) > 1e-14:
                    yield x, z, tri
