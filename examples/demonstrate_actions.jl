using TriMeshGame
using MeshPlotter
TM = TriMeshGame
MP = MeshPlotter

points = [-1. 0.
           0. -1.
           1. 0.
           0. 1.]
connectivity = [1  2  4
                2  3  4]
mesh = TM.Mesh(points, connectivity)

fig, ax = MP.plot_mesh(mesh)
fig

TM.edgeflip!(mesh, 1, 1)

fig, ax = MP.plot_mesh(mesh)
fig