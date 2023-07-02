using Test
# using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)
TM.split_interior_edge!(mesh, 1, 2)

tri_vertices = reshape(mesh.connectivity[:,1:10],1,:)
test_tri_vertices = [0 0 0 0 0 0 1 4 5 1 5 6 1 6 7 1 7 2 8 2 3 8 3 4 8 4 1 8 1 2]
@test allequal(test_tri_vertices, tri_vertices)

pairs = TM.make_edge_pairs(mesh)
test_pairs = [0, 0, 0, 0, 0, 0, 0, 12, 25, 0, 15, 8, 0, 18, 11, 0, 28, 14, 0, 24, 29, 0, 27, 20, 9, 30, 23, 17, 21, 26, 0, 0, 0, 0, 0, 0]
test_pairs[test_pairs .== 0] .= 37
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


mesh = TM.circlemesh(0)
d0 = TM.active_degrees(mesh)
TM.split_interior_edge!(mesh, 1, 2)
push!(d0, 6)
env = TM.GameEnv(mesh, d0)

@test allequal(env.d0[mesh.active_vertex], d0)
@test allequal(env.vertex_score[mesh.active_vertex], [0, 1, 0, 1, 0, 0, 0, -2])




mesh = TM.circlemesh(0)
d0 = TM.active_degrees(mesh)
env = TM.GameEnv(mesh, d0)
TM.step_collapse!(env, 5, 2)
connectivity = [7 2 3
                7 3 4
                7 4 5
                7 5 6]
allequal(TM.active_triangle_connectivity(env.mesh), connectivity')
t2t = [0 2 0
       0 3 1
       0 4 2
       0 0 3]
allequal(TM.active_triangle_t2t(env.mesh), t2t')
t2n = [0 3 0
       0 3 2
       0 3 2
       0 0 2]
allequal(TM.active_triangle_t2n(env.mesh), t2n')
d0 = [3,3,3,3,3,3]
allequal(TM.active_vertex_desired_degree(env), d0)
vs = [-1,0,0,0,-1,+2]
allequal(TM.active_vertex_score(env), vs)

mesh = TM.circlemesh(0)
d0 = TM.active_degrees(mesh)
env = TM.GameEnv(mesh, d0)
TM.step_collapse!(env, 6, 3)
connectivity = [1 2 3
                1 3 4
                1 4 5
                1 5 6]
allequal(TM.active_triangle_connectivity(env.mesh), connectivity')
t2t = [0 2 0
       0 3 1
       0 4 2
       0 0 3]
allequal(TM.active_triangle_t2t(env.mesh), t2t')
t2n = [0 3 0
       0 3 2
       0 3 2
       0 0 2]
allequal(TM.active_triangle_t2n(env.mesh), t2n')
d0 = [3,3,3,3,3,3]
allequal(TM.active_vertex_desired_degree(env), d0)
vs = [2,-1,0,0,0,-1]
allequal(TM.active_vertex_score(env), vs)





###############################################################################################
# TESTING ACTIVE EDGE PAIRS

mesh = TM.circlemesh(0)
TM.split_interior_edge!(mesh, 1, 2)

pairs = vec(TM.active_edge_pairs(mesh))
test_pairs = [0, 12, 25, 0, 15, 8, 0, 18, 11, 0, 28, 14, 0, 24, 29, 0, 27, 20, 9, 30, 23, 17, 21, 26]
@test allequal(test_pairs, pairs)

TM.reindex!(mesh)
pairs = TM.active_edge_pairs(mesh)
test_pairs = [
       0 0 0 0 0 0 3 11
       6 9 12 22 18 21 24 15
       19 2 5 8 23 14 17 20
]
test_pairs = vec(test_pairs)
@test allequal(test_pairs, pairs)
###############################################################################################