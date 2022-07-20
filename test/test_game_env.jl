using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)
TM.split_interior_edge!(mesh, 1, 2)

template = TM.make_template(mesh)
test_template = [0 0 0 0 0 0 1 4 5 1 5 6 1 6 7 1 7 2 8 2 3 8 3 4 8 4 1 8 1 2]
@test allequal(test_template, template)

pairs = TM.make_edge_pairs(mesh)
test_pairs = [0, 0, 0, 0, 0, 0, 0, 12, 25, 0, 15, 8, 0, 18, 11, 0, 28, 14, 0, 24, 29, 0, 27, 20, 9, 30, 23, 17, 21, 26]
