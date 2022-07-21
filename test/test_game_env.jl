using Test
using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)
TM.split_interior_edge!(mesh, 1, 2)

template = TM.make_template(mesh)
tri_vertices = reshape(mesh.t',1,:)
test_tri_vertices = [0 0 0 0 0 0 1 4 5 1 5 6 1 6 7 1 7 2 8 2 3 8 3 4 8 4 1 8 1 2]
@test allequal(test_tri_vertices, tri_vertices)

pairs = TM.make_edge_pairs(mesh)
test_pairs = [0, 0, 0, 0, 0, 0, 0, 12, 25, 0, 15, 8, 0, 18, 11, 0, 28, 14, 0, 24, 29, 0, 27, 20, 9, 30, 23, 17, 21, 26]
test_pairs[test_pairs .== 0] .= 31
@test allequal(test_pairs, pairs)

template = TM.make_template(mesh)

test_template_25 = [8,4,1,5,2,3,0,6,7,3,2,0]
@test allequal(test_template_25,template[:,25])

mesh = test_mesh_for_template()
template = TM.make_template(mesh)

test_template_13 = [4,7,8,13,5,3,12,14,9,2,1,6]
@test allequal(template[:,13],test_template_13)

test_template_11 = [3,7,4,8,1,6,13,5,0,0,0,0]
@test allequal(template[:,11],test_template_11)

mesh = TM.circlemesh(1)
d0 = copy(mesh.d)
TM.random_flips!(mesh, 5)
TM.averagesmoothing!(mesh, 3)

using MeshPlotter
MeshPlotter.plot_mesh(mesh, d0 = d0)[1]


# env = TM.GameEnv(mesh, mesh.d, 10)