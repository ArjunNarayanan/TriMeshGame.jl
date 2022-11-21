using Revise
using TriMeshGame
using MeshPlotter
TM = TriMeshGame
MP = MeshPlotter



##
s = sqrt(3)/2
vertices = [0.0  1.0  0.5   -0.5  -1.0  -0.5  0.5
            0.0  0.0  s      s     0.0  -s    -s]

connectivity = [1  1  1  1  1  1
                3  4  5  6  7  2
                4  5  6  7  2  3]

mesh = TM.Mesh(vertices, connectivity)
fig = MP.plot_mesh(TM.active_vertex_coordinates(mesh), TM.active_triangle_connectivity(mesh), number_vertices = true, number_elements = true, internal_order = true)
fig.tight_layout()
fig.savefig("examples/figures/hex_mesh.png")
##

##
t2t = TM.active_triangle_t2t(mesh)
##

##
t2n = TM.active_triangle_t2n(mesh)
##

##
TM.active_vertex_degrees(mesh)
##

function plot_verbose(mesh; fontsize = 15, vertex_size = 20)
    fig = MP.plot_mesh(TM.active_vertex_coordinates(mesh), TM.active_triangle_connectivity(mesh), number_vertices = true,
    number_elements = true, internal_order = true, fontsize = fontsize, vertex_size = vertex_size)
    fig.tight_layout()
    return fig
end

##
mesh = TM.circlemesh(0)
fig = plot_verbose(mesh)
fig.savefig("examples/figures/circlemesh-0.png")
##

##
mesh = TM.circlemesh(2)
fig = plot_verbose(mesh, fontsize = 10, vertex_size = 15)
fig.savefig("examples/figures/circlemesh-2.png")
##

##
mesh = TM.circlemesh(0)
fig = plot_verbose(mesh, fontsize = 30, vertex_size = 35)
fig.savefig("examples/figures/circlemesh-0.png")
TM.edgeflip!(mesh, 5, 2)
fig = plot_verbose(mesh, fontsize = 30, vertex_size = 35)
fig.savefig("examples/figures/flip-example.png")
##

##
mesh = TM.circlemesh(0)
TM.edgeflip!(mesh, 5, 2)
TM.edgeflip!(mesh, 5, 2)
fig = plot_verbose(mesh, fontsize = 30, vertex_size = 35)
fig.savefig("examples/figures/double-flip.png")
##

##
mesh = TM.circlemesh(0)
TM.split_boundary_edge!(mesh, 4, 1)
TM.reindex!(mesh)
fig = plot_verbose(mesh, fontsize = 30, vertex_size = 35)
fig.savefig("examples/figures/split-boundary.png")
##

##
TM.split_interior_edge!(mesh, 4, 2)
TM.reindex!(mesh)
fig = plot_verbose(mesh, fontsize = 30, vertex_size = 35)
fig.savefig("examples/figures/split-interior.png")
##

##
mesh = TM.circlemesh(0)
TM.collapse!(mesh, 6, 3)
fig = plot_verbose(mesh, fontsize = 30, vertex_size = 35)
fig.tight_layout()
fig.savefig("examples/figures/collapse-simple.png")
##

##
mesh = TM.circlemesh(0)
TM.split_interior_edge!(mesh, 5, 2)
TM.collapse!(mesh, 9, 3)
TM.reindex!(mesh)
fig = plot_verbose(mesh, fontsize = 30, vertex_size = 35)
fig.savefig("examples/figures/split-collapse.png")
##


##
mesh = TM.circlemesh(1)
fig = MP.plot_mesh(TM.active_vertex_coordinates(mesh), TM.active_triangle_connectivity(mesh))
# fig.savefig("examples/figures/ideal-mesh.png")
TM.random_actions!(mesh, 5)
TM.reindex!(mesh)
TM.averagesmoothing!(mesh)
fig = MP.plot_mesh(TM.active_vertex_coordinates(mesh), TM.active_triangle_connectivity(mesh))
fig.savefig("examples/figures/bad-connectivity-mesh.png")
##