function make_template(mesh)
    nt = total_num_triangles(mesh)
    et = [mesh.t[tri,ver] for tri in 1:nt for ver in 1:3]
    et = Array(reshape(et,1,:))
    return et
end

function make_edge_pairs(mesh)
    total_nt = total_num_triangles(mesh)
    pairs = zeros(Int, 3total_nt)
    for triangle in 1:total_nt
        for vertex in 1:3
            index = (triangle - 1)*3 + vertex
            opp_tri, opp_ver = mesh.t2t[triangle, vertex], mesh.t2n[triangle, vertex]
            pairs[index] = opp_tri == 0 ? 0 : (opp_tri - 1)*3 + opp_ver
        end
    end
    return pairs
end

function cycle_edges(x)
    nf, na = size(x)
    x = reshape(x, nf, 3, :)

    x1 = reshape(x, 3nf, 1, :)
    x2 = reshape(x[:,[2,3,1],:], 3nf, 1, :)
    x3 = reshape(x[:,[3,1,2],:], 3nf, 1, :)

    x = reshape(cat(x1, x2, x3, dims = 2), 3nf, :)
    return x
end

mutable struct GameEnv
    mesh0::Mesh
    mesh::Mesh
    d0::Vector{Int}
    vertex_score::Vector{Int}
    template::Matrix{Int}
    pairs::Vector{Int}
    num_initial_actions::Int
    max_actions
    num_actions
    initial_score
    current_score
    is_terminated
end

