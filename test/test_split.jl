using Test
# using Revise
using TriMeshGame
include("useful_routines.jl")

TM = TriMeshGame

mesh = TM.circlemesh(0)

@test TM.is_valid_interior_split(mesh, 1, 2; maxdegree = 4)
@test !TM.is_valid_interior_split(mesh, 1, 2; maxdegree = 3)

points = copy(TM.active_vertex_coordinates(mesh))
newp = 0.5*(points[:,1]+points[:,3])
points = [points newp]

@test TM.split_interior_edge!(mesh, 1, 2)

@test TM.num_triangles(mesh) == 8
@test allapprox(points, TM.active_vertex_coordinates(mesh))

testconn = [0 0 0
            0 0 0
            1 4 5
            1 5 6
            1 6 7
            1 7 2
            8 2 3
            8 3 4
            8 4 1
            8 1 2]
@test allequal(testconn', mesh.connectivity[:,1:10])

test_t2t = [0 0 0
            0 0 0
            0 4 9
            0 5 3
            0 6 4
            0 10 5
            0 8 10
            0 9 7
            3 10 8
            6 7 9]
@test allequal(test_t2t', mesh.t2t[:,1:10])

test_t2n = [0 0 0
            0 0 0
            0 3 1
            0 3 2
            0 3 2
            0 1 2
            0 3 2
            0 3 2
            3 3 2
            2 3 2]
@test allequal(mesh.t2n[:, 1:10], test_t2n')


active_tris = trues(10)
active_tris[[1,2]] .= false
@test allequal(active_tris, mesh.active_triangle[1:10])
@test count(mesh.active_triangle) == 8

testd = [6,4,3,4,3,3,3,4]
@test allequal(testd, mesh.degrees[1:8])

ver_on_bdry = trues(8)
ver_on_bdry[[1,8]] .= false
@test allequal(ver_on_bdry,mesh.vertex_on_boundary[1:8])

@test TM.num_vertices(mesh) == 8
@test TM.num_triangles(mesh) == 8


mesh = TM.circlemesh(0)
points = copy(mesh.vertices[:,1:7])
newp = 0.5*(points[:,2] + points[:,7])
points = [points newp]

@test TM.split_boundary_edge!(mesh, 6, 1)
@test allapprox(mesh.vertices[:,1:8], points)

test_conn = [1 2 3
             1 3 4
             1 4 5
             1 5 6
             1 6 7
             0 0 0
             8 1 7
             8 2 1]
@test allequal(test_conn', mesh.connectivity[:, 1:8])

test_t2t = [0 2 8
            0 3 1
            0 4 2
            0 5 3
            0 7 4
            0 0 0
            5 0 8
            1 7 0]
@test allequal(test_t2t', mesh.t2t[:, 1:8])

test_t2n = [0 3 1
            0 3 2
            0 3 2
            0 3 2
            0 1 2
            0 0 0
            2 0 2
            3 3 0]
@test allequal(test_t2n', mesh.t2n[:,1:8])


active_tris = trues(8)
active_tris[6] = false
@test allequal(active_tris, mesh.active_triangle[1:8])
@test count(mesh.active_triangle) == 7

testd = [7,3,3,3,3,3,3,3]
@test allequal(testd, mesh.degrees[1:8])

ver_on_bdry = falses(8)
ver_on_bdry[[2,3,4,5,6,7,8]] .= true
@test allequal(ver_on_bdry, mesh.vertex_on_boundary[1:8])


@test TM.num_vertices(mesh) == 8
@test TM.num_triangles(mesh) == 7

# using MeshPlotter
# mesh = TM.circlemesh(0)
# TM.split_interior_edge!(mesh, 3, 3)
# TM.split_boundary_edge!(mesh, 5, 1)
# TM.reindex_vertices!(mesh)
# TM.reindex_triangles!(mesh)
# MeshPlotter.plot_mesh(TM.active_vertex_coordinates(mesh), TM.active_connectivity(mesh))