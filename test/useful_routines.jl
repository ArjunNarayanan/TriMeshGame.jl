function allequal(u,v)
    return all(u .== v)
end

function allapprox(u,v)
    return all(u .≈ v)
end

function test_mesh_for_template()
    t = [1 3 4
         4 5 2
         7 3 6
         4 3 7
         4 7 8
         4 8 5
         5 8 9
         12 7 10
         7 12 13
         7 13 8
         14 8 13
         11 8 14
         12 15 13
         14 13 16]
    p = rand(16,2)

    mesh = TriMeshGame.Mesh(p, t)

    return mesh
end