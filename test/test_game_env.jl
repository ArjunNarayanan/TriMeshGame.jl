using Revise
using TriMeshGame

TM = TriMeshGame

mesh = TM.circlemesh(0)

TM.random_actions!(mesh, 5)
TM.averagesmoothing!(mesh, numiter = 3)
using MeshPlotter
MeshPlotter.plot_mesh(mesh)[1]


# TM.split_interior_edge!(mesh,1,2)

# nt = TM.total_num_triangles(mesh)
# et = [mesh.t[tri,ver] for tri in 1:nt for ver in 1:3 if TM.is_active_triangle(mesh,tri)]
