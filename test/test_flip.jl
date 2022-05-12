using Test
using Revise
using TriMeshGame
# include("plot_mesh.jl")

TM = TriMeshGame

nref = 4
p, t = TM.circlemesh(nref)

mesh = TM.Mesh(p, t)

valid_flip = [TM.isvalidflip(mesh, t, v) for v = 1:3, t in mesh.triangles]
test_valid_flip = ones(Bool,3,6)
test_valid_flip[1,:] .= false
@test all(valid_flip .== test_valid_flip)


flag = TM.flip!(mesh, TM.triangle(mesh, 1), 2)
# plot_mesh(mesh)

d = [TM.degree(mesh, t, i) for i = 1:3, t in mesh.triangles]
testd = [4 4 5 5 5 5
         2 4 4 3 3 3
         4 5 3 3 3 4]
@test all(d .== testd)

