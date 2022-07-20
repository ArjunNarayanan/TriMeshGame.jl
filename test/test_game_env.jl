using Revise
using TriMeshGame

TM = TriMeshGame

mesh = TM.circlemesh(0)
TM.split_interior_edge!(mesh, 1, 2)

template = TM.make_template(mesh)
pairs 