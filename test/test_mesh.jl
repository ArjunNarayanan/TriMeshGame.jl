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
@test allequal(t,mesh.t)

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
         6 7]
@test allequal(mesh.edges,edges)

t2t = [0 2 6
       0 3 1
       0 4 2
       0 5 3
       0 6 4
       0 1 5]
@test allequal(mesh.t2t,t2t)

t2n = repeat([0,3,2]',6)
@test allequal(t2n,mesh.t2n)

t2e = [7 2 1
       9 3 2
       10 4 3
       11 5 4
       12 6 5
       8 1 6]
@test allequal(t2e,mesh.t2e)

d = [6,3,3,3,3,3,3]
@test allequal(d,mesh.d)

bnd_nodes = [2,3,4,5,6,7]
@test allequal(bnd_nodes,mesh.boundary_vertex)

boundary_edges = [7,8,9,10,11,12]
@test allequal(boundary_edges,mesh.boundary_edges)

node_on_boundary = [false,true,true,true,true,true,true]
@test allequal(node_on_boundary,mesh.vertex_on_boundary)

@test TM.num_edges(mesh) == 12
@test TM.num_triangles(mesh) == 6
@test all(mesh.active_triangle)
@test all(mesh.active_edge)

mesh = TM.circlemesh(0)
mesh = TM.refine(mesh)
@test TM.num_triangles(mesh) == 24

using MeshPlotter

f, a = MeshPlotter.plot_mesh(mesh, d0 = mesh.d)
f