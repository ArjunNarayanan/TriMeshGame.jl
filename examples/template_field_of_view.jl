using TriMeshGame
using MeshPlotter
TM = TriMeshGame
MP = MeshPlotter

function plot_mesh(
    mesh; 
    mark_vertices=[],
    index_vertices = nothing,
    number_elements=false
    )
    fig, ax = MP.plot_mesh(
        TM.active_vertex_coordinates(mesh),
        TM.active_triangle_connectivity(mesh),
        mark_vertices=mark_vertices,
        index_vertices=index_vertices,
        vertex_size=40,
        number_elements=number_elements,
        fontsize=30
    )
    return fig
end

mesh = TM.circlemesh(1)
plot_mesh(mesh)

element_number = 4
local_half_edge_idx = 1
half_edge_idx = (element_number-1)*3 + local_half_edge_idx

pairs = TM.make_edge_pairs(mesh)
x = reshape(mesh.connectivity, 1, :)
mark_vertices = x[:,half_edge_idx]
index_vertices=Dict(
    "vertex_ids" => mark_vertices,
    "vertex_numbers" => [1]
)
fig = plot_mesh(
    mesh,
    mark_vertices=mark_vertices,
    index_vertices=index_vertices
)
fig.tight_layout()
fig.savefig("examples/paper_figures/template-l1.pdf")

cx = TM.cycle_edges(x)
mark_vertices = cx[:,half_edge_idx]
index_vertices = Dict(
    "vertex_ids" => mark_vertices,
    "vertex_numbers" => 1:3
)
fig = plot_mesh(
    mesh, 
    mark_vertices=mark_vertices,
    index_vertices=index_vertices
)
fig.tight_layout()
fig.savefig("examples/paper_figures/template-l2.pdf")

px = TM.zero_pad(x)[:, pairs]
cpx = TM.cycle_edges(px)
mark_vertices=vcat(
    mark_vertices,
    cpx[:,half_edge_idx]
)
index_vertices = Dict(
    "vertex_ids" => mark_vertices,
    "vertex_numbers" => 1:6 
)
fig = plot_mesh(
    mesh, 
    mark_vertices=mark_vertices,
    index_vertices=index_vertices
)
fig.tight_layout()
fig.savefig("examples/paper_figures/template-l3.pdf")

pcpx = TM.zero_pad(cpx)[2:3, pairs]
cpcpx = TM.cycle_edges(pcpx)
mark_vertices = vcat(
    mark_vertices,
    cpcpx[:,half_edge_idx]
)
index_vertices=Dict(
    "vertex_ids" => mark_vertices,
    "vertex_numbers" => 1:12
)
fig = plot_mesh(
    mesh, 
    mark_vertices=mark_vertices,
    index_vertices=index_vertices
)
fig.tight_layout()
fig.savefig("examples/paper_figures/template-l4.pdf")


# pcpcpx = TM.zero_pad(cpcpx)[3:6, pairs]
# cpcpcpx = TM.cycle_edges(pcpcpx)
# mark_vertices = vcat(
#     mark_vertices,
#     cpcpcpx[:,half_edge_idx]
# )
# index_vertices=Dict(
#     "vertex_ids" => mark_vertices,
#     "vertex_numbers" => 1:24
# )
# plot_mesh(
#     mesh,
#     mark_vertices=mark_vertices,
#     index_vertices=index_vertices
# )