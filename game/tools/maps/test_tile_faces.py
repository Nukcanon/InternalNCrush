import math
import unittest
from tile_faces import tiled_triangles


def area_vector(triangle):
    a,b,c=triangle
    u=[b[i]-a[i] for i in range(3)];v=[c[i]-a[i] for i in range(3)]
    return [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]


class TileFaces(unittest.TestCase):
    def test_floor_wall_slope_and_exact_boundary(self):
        for points in [
            [(0,0,0),(120,0,0),(0,0,120)],
            [(0,0,4),(120,0,4),(0,7,4)],
            [(0,0,0),(120,4,0),(0,0,120)],
            [(60,0,60),(60,7,60),(60,0,84)],
        ]:
            original=area_vector(points);parts=list(tiled_triangles(points,60,60))
            self.assertTrue(parts)
            combined=[sum(area_vector(t)[i] for _,_,t in parts) for i in range(3)]
            for a,b in zip(original,combined):self.assertAlmostEqual(a,b,places=6)
            for x,z,triangle in parts:
                self.assertGreater(sum(a*b for a,b in zip(original,area_vector(triangle))),0)
                for p in triangle:
                    self.assertTrue(60+x*24-1e-7<=p[0]<=60+(x+1)*24+1e-7)
                    self.assertTrue(60+z*24-1e-7<=p[2]<=60+(z+1)*24+1e-7)


if __name__=='__main__':unittest.main()
