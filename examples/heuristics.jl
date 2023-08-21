using TriMeshGame
using MeshPlotter

TM = TriMeshGame
MP = MeshPlotter

mesh = TM.circlemesh(0)
fig, ax = MP.plot_mesh(
    TM.active_vertex_coordinates(mesh),
    TM.active_triangle_connectivity(mesh)
)
fig.savefig("examples/figures/heuristic-interior.png")