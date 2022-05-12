using Test
using Revise
using TriMeshGame
include("plot_mesh.jl")

TM = TriMeshGame

nref = 0
p, t = TM.circlemesh(nref)

mesh = TM.Mesh(p, t)
# plot_mesh(mesh)

valid_flip = [TM.isvalidflip(mesh, t, v) for v = 1:3, t in mesh.triangles]
test_valid_flip = ones(Bool,3,6)
test_valid_flip[1,:] .= false
@test all(valid_flip .== test_valid_flip)
