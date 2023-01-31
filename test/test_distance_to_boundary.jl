using Test
# using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)
queue = TM.initialize_queue_with_boundary_edges(mesh)
test_queue = [(i,1) for i in 1:6]
@test allequal(queue, test_queue)

distances = TM.initialize_distance_to_boundary(test_queue, mesh)
test_distances = fill(-1, TM.vertex_buffer(mesh))
test_distances[[2,3,4,5,6,7]] .= 0
@test allequal(distances, test_distances)

TM.update_neighbor_distances!(1, 1, distances, queue, mesh)
test_distances[1] = 1
@test allequal(distances, test_distances)

distances = TM.compute_distance_to_boundary(mesh)
@test allequal(test_distances, distances)


mesh = TM.circlemesh(0)
queue = []
distances = fill(-1,TM.vertex_buffer(mesh))
distances[1] = 0
TM.update_neighbor_distances!(1, 3, distances, queue, mesh)
test_queue = [(i,1) for i in 1:6]
@test allequal(queue, test_queue)
test_distances = fill(-1, TM.vertex_buffer(mesh))
test_distances[1] = 0
test_distances[[2,3,4,5,6,7]] .= 1
@test allequal(distances, test_distances)


mesh = TM.circlemesh(1)
distances = TM.compute_distance_to_boundary(mesh)
test_distances = fill(-1, TM.vertex_buffer(mesh))
test_distances[[2,3,4,5,6,7,14,16,17,18,19,15]] .= 0
test_distances[[8,9,10,11,12,13]] .= 1
test_distances[1] = 2
@test allequal(distances, test_distances)


############################################################################################################
# showcase
# using RandomQuadMesh
# using MeshPlotter
# MP = MeshPlotter
# RQ = RandomQuadMesh
# polygon_degree = 20
# hmax = 0.2
# boundary_pts = RQ.random_polygon(20)
# mesh = RQ.tri_mesh(boundary_pts, hmax = hmax, allow_vertex_insert = true)
# mesh = TM.Mesh(mesh.p, mesh.t)
# distances = TM.compute_distance_to_boundary(mesh)
# MP.plot_mesh(TM.active_vertex_coordinates(mesh), TM.active_triangle_connectivity(mesh),
# vertex_score = distances[mesh.active_vertex], vertex_size = 30)[1]