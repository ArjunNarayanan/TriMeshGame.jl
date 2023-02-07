using Revise
using TriMeshGame
using MeshPlotter
TM = TriMeshGame
MP = MeshPlotter

function plot_mesh(mesh; fontsize = 30, vertex_size = 30)
    fig = MP.plot_mesh(
        TM.active_vertex_coordinates(mesh), 
        TM.active_triangle_connectivity(mesh), 
        number_vertices = true, 
        number_elements = true, 
        # internal_order = true,
        vertex_size = vertex_size, 
        fontsize = fontsize)[1]

    fig.tight_layout()    
    return fig
end

##
vertices = [0. 1. 1. 2.
            0. -1. 1. 0.]
connectivity = [1 2 4
                1 4 3]

mesh = TM.Mesh(vertices, connectivity')
fig = plot_mesh(mesh, fontsize = 60, vertex_size = 70)
fig.savefig("examples/paper_figures/flip-0.png")
TM.edgeflip!(mesh, 1, 2)
fig = plot_mesh(mesh, fontsize = 60, vertex_size = 70)
fig.savefig("examples/paper_figures/flip-1.png")
##

##
vertices = [0. 1. 1. 2.
            0. -1. 1. 0.]
connectivity = [1 2 4
                1 4 3]

mesh = TM.Mesh(vertices, connectivity')
fig = plot_mesh(mesh, fontsize = 60, vertex_size = 70)
fig.savefig("examples/paper_figures/interior-split-0.png")
TM.split_interior_edge!(mesh, 1, 2)
fig = plot_mesh(mesh, fontsize = 60, vertex_size = 70)
fig.savefig("examples/paper_figures/interior-split-1.png")
##

