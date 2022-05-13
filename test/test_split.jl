using Test
using Revise
using TriMeshGame
include("plot_mesh.jl")

TM = TriMeshGame

nref = 0
p, t = TM.circlemesh(nref)
mesh = TM.Mesh(p, t)
t = TM.triangle(mesh, 1)

TM.split!(mesh, t)
plot_mesh(mesh)

@test TM.number_of_triangles(mesh) == 8
@test TM.number_of_vertices(mesh) == 8

d = [TM.degree(mesh, t, i) for i = 1:3, t in mesh.triangles]

testd = [7 7 7 7 7 3 3 3
         4 3 3 3 3 4 4 7
         3 3 3 3 4 4 7 4]
@test all(d .== testd)

t = TM.triangle(mesh, 1)
TM.flip!(mesh, t, 3)

plot_mesh(mesh)
