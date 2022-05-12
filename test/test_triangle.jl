using Test
using Revise
using TriMeshGame
# include("plot_mesh.jl")

TM = TriMeshGame

@test TM.next(1) == 2
@test TM.next(2) == 3
@test TM.next(3) == 1

@test TM.previous(1) == 3
@test TM.previous(2) == 1
@test TM.previous(3) == 2


