using Revise
using TriMeshGame
include("plot_mesh.jl")

TM = TriMeshGame

nref = 1
p, t = TM.circlemesh(nref)
mesh = TM.Mesh(p, t)

plot_mesh(mesh)