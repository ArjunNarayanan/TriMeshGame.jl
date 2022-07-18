using Revise
using TriMeshGame
using MeshPlotter

TM = TriMeshGame
MP = MeshPlotter

p, t = TM.template_circlemesh()
mesh0 = TM.Mesh(p, t)

MP.plot_mesh(mesh0)[1]

e, be, t2e = TM.all_edges(t)

p, t = TM.refine(p, t, e, t2e)
e, be, t2e = TM.all_edges(t)
bn = TM.boundary_vertices(e, be)
TM.correct_boundary_vertices!(p, bn)
TM.averagesmoothing!(p, e, trues(size(e,1)),bn,numiter=5)

mesh1 = TM.Mesh(p, t)
MP.plot_mesh(mesh1)[1]

mesh = TM.circlemesh(2)
MP.plot_mesh(mesh)[1]