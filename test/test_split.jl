using Test
# using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)

points = copy(mesh.p)
newp = 0.5*(points[1,:]+points[3,:])
points = [points; newp']

TM.split_interior_edge!(mesh, 1, 2)

@test allapprox(points, mesh.p)

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

test_edges = [1 2
              1 3
              1 4
              1 5
              1 6
              1 7
              2 3
              2 7
              3 4
              4 5
              5 6
              6 7
              2 8
              3 8
              4 8
              1 8]
@test allequal(test_edges, mesh.edges)

test_t2e = [7 2 1
            9 3 2
            10 4 3
            11 5 4
            12 6 5
            8 1 6
            7 14 13
            9 15 14
            3 16 15
            1 13 16]
@test allequal(test_t2e, mesh.t2e)

active_tris = trues(10)
active_tris[[1,2]] .= false
@test allequal(active_tris, mesh.active_triangle)

active_edges = trues(16)
active_edges[2] = false
@test allequal(active_edges, mesh.active_edge)

testd = [6,4,3,4,3,3,3,4]
@test allequal(testd, mesh.d)

bdry_edges = [7,8,9,10,11,12]
edge_on_boundary = falses(16)
edge_on_boundary[bdry_edges] .= true
@test allequal(mesh.edge_on_boundary, edge_on_boundary)

ver_on_bdry = trues(8)
ver_on_bdry[[1,8]] .= false
@test allequal(ver_on_bdry,mesh.vertex_on_boundary)

@test TM.num_vertices(mesh) == 8
@test TM.num_triangles(mesh) == 8
@test TM.num_edges(mesh) == 15
@test TM.total_num_edges(mesh) == 16
@test TM.total_num_triangles(mesh) == 10


mesh = TM.circlemesh(0)
TM.split_boundary_edge!(mesh, 6, 1)

test_conn = [1 2 3
             1 3 4
             1 4 5
             1 5 6
             1 6 7
             1 7 2
             8 1 7
             8 2 1]
@test allequal(test_conn, mesh.t)

test_t2t = [0 2 8
            0 3 1
            0 4 2
            0 5 3
            0 7 4
            0 1 5
            5 0 8
            1 7 0]
@test allequal(test_t2t, mesh.t2t)

test_t2n = [0 3 1
            0 3 2
            0 3 2
            0 3 2
            0 1 2
            0 3 2
            2 0 2
            3 3 0]
@test allequal(test_t2n, mesh.t2n)

edges = [1 2
         1 3
         1 4
         1 5
         1 6
         1 7
         2 3
         2 7
         3 4
         4 5
         5 6
         6 7
         1 8
         7 8
         2 8]
@test allequal(edges, mesh.edges)

test_t2e = [7 2 1
            9 3 2
            10 4 3
            11 5 4
            12 6 5
            8 1 6
            6 14 13
            1 13 15]
@test allequal(test_t2e, mesh.t2e)

active_tris = trues(8)
active_tris[6] = false
@test allequal(active_tris, mesh.active_triangle)

active_edges = trues(15)
active_edges[8] = false
@test allequal(active_edges, mesh.active_edge)

testd = [7,3,3,3,3,3,3,3]
@test allequal(testd, mesh.d)

ver_on_bdry = falses(8)
ver_on_bdry[[2,3,4,5,6,7,8]] .= true
@test allequal(ver_on_bdry, mesh.vertex_on_boundary)

edge_on_boundary = falses(15)
edge_on_boundary[[7,8,9,10,11,12,14,15]] .= true
@test allequal(mesh.edge_on_boundary, edge_on_boundary)

@test TM.num_vertices(mesh) == 8
@test TM.num_triangles(mesh) == 7
@test TM.num_edges(mesh) == 14
@test TM.total_num_edges(mesh) == 15
@test TM.total_num_triangles(mesh) == 8

using MeshPlotter
mesh = TM.circlemesh(0)
TM.split_interior_edge!(mesh, 3, 3)
TM.split_boundary_edge!(mesh, 5, 1)
MeshPlotter.plot_mesh(mesh)[1]