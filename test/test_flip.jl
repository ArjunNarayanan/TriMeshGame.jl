using Test
using Revise
using TriMeshGame
using MeshPlotter

TM = TriMeshGame

nref = 0
mesh = TM.circlemesh(0)

f, ax = MeshPlotter.plot_mesh(mesh)
f


mesh = TM.Mesh(p, t)

valid_flip = [TM.isvalidflip(mesh, t, v) for v = 1:3, t in mesh.triangles]
test_valid_flip = ones(Bool,3,6)
test_valid_flip[1,:] .= false
@test all(valid_flip .== test_valid_flip)


@test TM.flip!(mesh, TM.triangle(mesh, 1), 2)
# plot_mesh(mesh)

d = [TM.degree(mesh, t, i) for i = 1:3, t in mesh.triangles]
testd = [4 4 5 5 5 5
         2 4 4 3 3 3
         4 5 3 3 3 4]
@test all(d .== testd)

t = TM.index_vertex_connectivity(mesh)
testt = [2 2 1 1 1 1
         3 4 4 5 6 7
         4 1 5 6 7 2]
@test all(t .== testt)

t2t = TM.index_triangle_connectivity(mesh)
testt2t = [0 3 0 0 0 0
           2 6 4 5 6 2
           0 1 2 3 4 5]
@test all(t2t .== testt2t)