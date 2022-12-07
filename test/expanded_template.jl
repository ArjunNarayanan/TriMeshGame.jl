using Test
using Revise
using TriMeshGame
using MeshPlotter

TM = TriMeshGame
MP = MeshPlotter

mesh = TM.circlemesh(1)


pairs = TM.make_edge_pairs(mesh)

x = reshape(mesh.connectivity, 1, :)

cx = TM.cycle_edges(x)
px = TM.zero_pad(x)[:, pairs]

cpx = TM.cycle_edges(px)
pcpx = TM.zero_pad(cpx)[2:3, pairs]

cpcpx = TM.cycle_edges(pcpx)
pcpcpx = TM.zero_pad(cpcpx)[3:6, pairs]

cpcpcpx = TM.cycle_edges(pcpcpx)
pcpcpcpx = TM.zero_pad(cpcpcpx)[5:12, pairs]

cpcpcpcpx = TM.cycle_edges(pcpcpcpx)

new_template = vcat(cx, cpx, cpcpx, cpcpcpx, cpcpcpcpx)

# MP.plot_mesh(TM.active_vertex_coordinates(mesh), TM.active_triangle_connectivity(mesh),
# number_elements = true, number_vertices = true, internal_order = true)

# template = TM.make_template(mesh)