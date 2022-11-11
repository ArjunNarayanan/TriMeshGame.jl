using Test
using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)

t = [1 2 3
     1 3 4
     1 4 5
     1 5 6
     1 6 7
     1 7 2]
@test allequal(t',TM.active_connectivity(mesh))

t2t = [0 2 6
       0 3 1
       0 4 2
       0 5 3
       0 6 4
       0 1 5]
@test allequal(TM.active_t2t(mesh),t2t')

t2n = repeat([0,3,2]',6)
@test allequal(t2n',TM.active_t2n(mesh))

d = [6,3,3,3,3,3,3]
@test allequal(d,TM.active_degrees(mesh))

node_on_boundary = [false,true,true,true,true,true,true]
@test allequal(node_on_boundary,mesh.vertex_on_boundary[mesh.active_vertex])

@test TM.num_triangles(mesh) == 6
@test all(mesh.active_triangle[1:6])
@test count(mesh.active_triangle) == 6
@test all(mesh.active_vertex[1:7])
@test count(mesh.active_vertex) == 7

