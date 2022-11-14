using Test
# using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)
@test !TM.is_valid_flip(mesh,1,1)
@test !TM.is_valid_flip(mesh,2,1)
@test !TM.is_valid_flip(mesh,3,1)
@test !TM.is_valid_flip(mesh,4,1)
@test !TM.is_valid_flip(mesh,5,1)
@test !TM.is_valid_flip(mesh,6,1)

@test TM.is_valid_flip(mesh,1,2)
@test TM.is_valid_flip(mesh,1,3)

@test !TM.is_valid_flip(mesh,1,3,maxdegree=3)
@test !TM.is_valid_flip(mesh,1,2,maxdegree=3)

@test TM.edgeflip!(mesh,1,2)
@test TM.edgeflip!(mesh,4,2)
@test TM.edgeflip!(mesh,6,3)
@test !TM.is_valid_flip(mesh,2,1)

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
@test allequal(testconn', TM.active_connectivity(mesh))
test_tri_conn = [0 2 0
                 3 6 1
                 0 4 2
                 0 5 3
                 0 6 4
                 0 2 5]
@test allequal(test_tri_conn', TM.active_t2t(mesh))
test_opp_ver = [0 3 0
                3 2 2
                0 3 1
                0 3 2
                0 3 2
                0 2 2]
@test allequal(test_opp_ver', TM.active_t2n(mesh))

test_deg = [5, 4, 2, 4, 3, 3, 3]
@test allequal(test_deg, TM.active_degrees(mesh))