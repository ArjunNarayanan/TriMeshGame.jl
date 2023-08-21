using Revise
using TriMeshGame
using MeshPlotter
TM = TriMeshGame
MP = MeshPlotter


function plot_mesh(mesh; fontsize = 60, vertex_size = 70)
    fig, ax = MP.plot_mesh(
        TM.active_vertex_coordinates(mesh), 
        TM.active_triangle_connectivity(mesh), 
        number_vertices = true, 
        # number_elements = true, 
        # internal_order = true,
        vertex_size = vertex_size, 
        fontsize = fontsize)

    fig.tight_layout()    
    return fig
end


##
vertices = [0. 1. 1. 2.
            0. -1. 1. 0.]
connectivity = [1 2 4
                1 4 3]

mesh = TM.Mesh(vertices, connectivity')
fig = plot_mesh(mesh)
fig.tight_layout()
fig.savefig("examples/paper_figures/flip-0.pdf")
TM.edgeflip!(mesh, 1, 2)
fig = plot_mesh(mesh, fontsize = 60, vertex_size = 70)
fig.tight_layout()
fig.savefig("examples/paper_figures/flip-1.pdf")
##

##
vertices = [0. 1. 1. 2.
            0. -1. 1. 0.]
connectivity = [1 2 4
                1 4 3]

mesh = TM.Mesh(vertices, connectivity')
fig = plot_mesh(mesh, fontsize = 60, vertex_size = 70)
fig.tight_layout()
fig.savefig("examples/paper_figures/interior-split-0.pdf")
TM.split_interior_edge!(mesh, 1, 2)
fig = plot_mesh(mesh, fontsize = 60, vertex_size = 70)
fig.tight_layout()
fig.savefig("examples/paper_figures/interior-split-1.pdf")
##


##
vertices = [0. 0. 1. 2. 2. 3. 4. 4.
            0. 2. 1. 0. 2. 1. 0. 2.]
connectivity = [
    1 1 3 3 3 4 6 6
    3 4 5 4 6 7 8 7
    2 3 2 6 5 6 5 8
]
mesh = TM.Mesh(vertices, connectivity)
fig = plot_mesh(mesh, fontsize = 50, vertex_size = 50)
fig.tight_layout()
fig.savefig("examples/paper_figures/collapse-0.pdf")
TM.collapse!(mesh, 4, 2)
TM.reindex!(mesh)
fig = plot_mesh(mesh, fontsize = 50, vertex_size=50)
fig.tight_layout()
fig.savefig("examples/paper_figures/collapse-1.pdf")
##