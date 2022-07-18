using Test
using Revise
using TriMeshGame
using MeshPlotter
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)

TM.split_interior_edge!(mesh, 1, 2)

testconn = [1 2 3
            1 3 4
            1 4 5
            1 5 6
            1 6 7
            1 7 2
            8 2 3
            8 3 4
            8 4 1
            8 1 2]
@test allequal(testconn, mesh.t)

test_t2t = [0 2 6
            0 3 1
            0 4 9
            0 5 3
            0 6 4
            0 10 5
            0 8 10
            0 9 7
            3 10 8
            6 7 9]
@test allequal(test_t2t, mesh.t2t)

test_t2n = [0 3 2
            0 3 2
            0 3 1
            0 3 2
            0 3 2
            0 1 2
            0 3 2
            0 3 2
            3 3 2
            2 3 2]
@test allequal(mesh.t2n, test_t2n)

test_edges = 