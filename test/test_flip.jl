using Test
using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)
@test !TM.isvalidflip(mesh,1,1)
@test !TM.isvalidflip(mesh,2,1)
@test !TM.isvalidflip(mesh,3,1)
@test !TM.isvalidflip(mesh,4,1)
@test !TM.isvalidflip(mesh,5,1)
@test !TM.isvalidflip(mesh,6,1)

@test TM.isvalidflip(mesh,1,2)
@test TM.isvalidflip(mesh,1,3)

@test !TM.isvalidflip(mesh,1,3,maxdegree=3)
@test !TM.isvalidflip(mesh,1,2,maxdegree=3)

TM.edgeflip!(mesh,1,2)
TM.edgeflip!(mesh,4,2)
TM.edgeflip!(mesh,6,3)
@test !TM.isvalidflip(mesh,2,1)

mesh = TM.circlemesh(0)
@test TM.edgeflip!(mesh,1,Int32(2))

mesh = TM.circlemesh(0)
@test TM.edgeflip!(mesh,1,2)
testconn = [2 3 4
            2 4 1
            1 4 5
            1 5 6
            1 6 7
            1 7 2]
@test allequal(testconn, mesh.t)
test_tri_conn = [0 2 0
                 3 6 1
                 0 4 2
                 0 5 3
                 0 6 4
                 0 2 5]
@test allequal(test_tri_conn, mesh.t2t)
test_opp_ver = [0 3 0
                3 2 2
                0 3 1
                0 3 2
                0 3 2
                0 2 2]
@test allequal(test_opp_ver, mesh.t2n)

test_t2e = [9 2 7
            3 1 2
            10 4 3
            11 5 4
            12 6 5
            8 1 6]
@test allequal(test_t2e, mesh.t2e)

test_edges = [1 2
              2 4
              1 4
              1 5
              1 6
              1 7
              2 3
              2 7
              3 4
              4 5
              5 6
              6 7]
@test allequal(test_edges, mesh.edges)

test_deg = [5, 4, 2, 4, 3, 3, 3]
@test allequal(test_deg, mesh.d)