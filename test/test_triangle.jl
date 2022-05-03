using Revise
using TriMeshGame
using EdgeFlip

TM = TriMeshGame

nref = 1
p, t = TM.circlemesh(nref)
m = EdgeFlip.generate_mesh(nref)

all(m.p .≈ p')
all(m.t .== t')

mesh = TM.Mesh(p, t)