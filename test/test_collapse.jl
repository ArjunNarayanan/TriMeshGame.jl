using Test
# using Revise
using TriMeshGame
# using MeshPlotter
include("useful_routines.jl")

TM = TriMeshGame
# MP = MeshPlotter

# function plot_verbose(mesh; fontsize = 15, vertex_size = 20)
#     fig = MP.plot_mesh(TM.active_vertex_coordinates(mesh), TM.active_triangle_connectivity(mesh), number_vertices = true,
#     number_elements = true, internal_order = true, fontsize = fontsize, vertex_size = vertex_size)
#     fig.tight_layout()
#     return fig
# end

vertices = [0. 1. 0.5 0.5
            0. 0. 1. -1.]
connectivity = [1 1
                2 4
                3 2]
mesh = TM.Mesh(vertices, connectivity)
@test !TM.is_valid_collapse(mesh, 1, 3)

mesh = TM.circlemesh(0)
@test !TM.is_valid_collapse(mesh, 1, 1)
@test TM.is_valid_collapse(mesh, 1, 2)
@test TM.collapse!(mesh, 4, 2)

test_conn = [6 6 6 0 0 6
             2 3 4 0 0 7
             3 4 5 0 0 2]
@test allequal(test_conn, mesh.connectivity[:,1:6])
test_t2t = [0 0 0 0 0 0
            2 3 0 0 0 1
            6 1 2 0 0 0]
@test allequal(test_t2t, mesh.t2t[:,1:6])
test_t2n = [0 0 0 0 0 0
            3 3 0 0 0 3
            2 2 2 0 0 0]
@test allequal(test_t2n, mesh.t2n[:,1:6])
active_triangles = trues(6)
active_triangles[[4,5]] .= false
@test allequal(mesh.active_triangle[1:6], active_triangles)
@test count(mesh.active_triangle) == 4
@test TM.num_triangles(mesh) == 4 
active_vertices = trues(7)
active_vertices[1] = false
@test allequal(mesh.active_vertex[1:7],active_vertices)
@test count(mesh.active_vertex) == 6
@test TM.num_vertices(mesh) == 6
degree = [0,3,3,3,2,5,2]
@test allequal(mesh.degrees[1:7],degree)

mesh = TM.circlemesh(0)
@test TM.split_interior_edge!(mesh, 5, 2)
@test TM.is_valid_collapse(mesh, 10, 3)
@test TM.collapse!(mesh, 10, 3)

test_conn = [8  8   8   8   0   0   8   8   0   0
             2  3   4   5   0   0   6   7   0   0
             3  4   5   6   0   0   7   2   0   0]
@test allequal(mesh.connectivity[:,1:10], test_conn)

test_t2t = [0 0 0 0 0 0 0 0 0 0
            2 3 4 7 0 0 8 1 0 0
            8 1 2 3 0 0 4 7 0 0]
@test allequal(mesh.t2t[:,1:10], test_t2t)

test_t2n = repeat([0,3,2], inner = (1,10))
test_t2n[:,[5,6,9,10]] .= 0
@test allequal(test_t2n, mesh.t2n[:,1:10])

active_triangles = trues(10)
active_triangles[[5,6,9,10]] .= false
@test allequal(mesh.active_triangle[1:10], active_triangles)
@test count(mesh.active_triangle) == 6
active_vertex = trues(8)
active_vertex[1] = false
@test allequal(mesh.active_vertex[1:8], active_vertex)
@test count(mesh.active_vertex) == 7
degree = [0,3,3,3,3,3,3,6]
@test allequal(degree, mesh.degrees[1:8])


############################################################################################################
# TEST TRIANGLE INVERTION
vertices = zeros(2,9)
connectivity = [1 2 4
                2 3 5
                1 4 6
                4 2 5
                5 3 8
                4 5 7
                6 4 9
                4 7 9
                9 7 5
                5 8 9]
mesh = TM.Mesh(vertices, connectivity')

@test !TM.is_valid_collapse(mesh, 6, 3)
@test !TM.is_valid_collapse(mesh, 4, 2)