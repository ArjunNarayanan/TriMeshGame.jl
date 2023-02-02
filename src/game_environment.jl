function make_template(mesh)
    pairs = make_edge_pairs(mesh)

    tri_vertices = reshape(mesh.connectivity, 1, :)

    ct = cycle_edges(tri_vertices)

    p = zero_pad(tri_vertices)[:, pairs]
    cp1 = cycle_edges(p)

    p = zero_pad(cp1)[[2, 3], pairs]
    cp2 = cycle_edges(p)

    template = vcat(ct, cp1, cp2)

    return template
end

function make_level4_template(mesh)
    pairs = make_edge_pairs(mesh)

    x = reshape(mesh.connectivity, 1, :)

    cx = cycle_edges(x)
    px = zero_pad(x)[:, pairs]

    cpx = cycle_edges(px)
    pcpx = zero_pad(cpx)[2:3, pairs]

    cpcpx = cycle_edges(pcpx)
    pcpcpx = zero_pad(cpcpx)[3:6, pairs]

    cpcpcpx = cycle_edges(pcpcpx)
    pcpcpcpx = zero_pad(cpcpcpx)[5:12, pairs]

    cpcpcpcpx = cycle_edges(pcpcpcpx)

    template = vcat(cx, cpx, cpcpx, cpcpcpx, cpcpcpcpx)

    return template
end

function make_edge_pairs(mesh)
    total_nt = triangle_buffer(mesh)
    pairs = zeros(Int, 3total_nt)
    nbr_idx = 3total_nt + 1
    for triangle = 1:total_nt
        for vertex = 1:3
            index = (triangle - 1) * 3 + vertex
            opp_tri, opp_ver = mesh.t2t[vertex, triangle], mesh.t2n[vertex, triangle]
            pairs[index] = opp_tri == 0 ? nbr_idx : (opp_tri - 1) * 3 + opp_ver
        end
    end
    return pairs
end

function cycle_edges(x)
    nf, na = size(x)
    x = reshape(x, nf, 3, :)

    x1 = reshape(x, 3nf, 1, :)
    x2 = reshape(x[:, [2, 3, 1], :], 3nf, 1, :)
    x3 = reshape(x[:, [3, 1, 2], :], 3nf, 1, :)

    x = reshape(cat(x1, x2, x3, dims=2), 3nf, :)
    return x
end

function zero_pad(m)
    return zero_pad(m, 1)
end

mutable struct GameEnv
    mesh::Mesh
    d0::Vector{Int}
    vertex_score::Vector{Int}
end

function global_score(vertex_score)
    return sum(abs.(vertex_score))
end

function optimum_score(vertex_score)
    return abs(sum(vertex_score))
end

function check_terminated(num_actions, max_actions, current_score, opt_score)
    return num_actions >= max_actions || current_score <= opt_score
end

function check_terminated(env::GameEnv)
    return check_terminated(
        env.num_actions,
        env.max_actions,
        env.current_score,
        env.opt_score,
    )
end

function GameEnv(mesh0, d0)
    @assert length(d0) == num_vertices(mesh0)

    mesh = deepcopy(mesh0)
    exp_d0 = zeros(Int, vertex_buffer(mesh))
    exp_d0[mesh.active_vertex] .= d0

    vertex_score = mesh.degrees - exp_d0
    GameEnv(
        mesh,
        exp_d0,
        vertex_score,
    )
end

function active_vertex_score(env)
    return env.vertex_score[env.mesh.active_vertex]
end

function Base.show(io::IO, env::GameEnv)
    nv = num_vertices(env.mesh)
    nt = num_triangles(env.mesh)

    println(io, "GameEnv")
    println(io, "   num verts : $nv")
    println(io, "   num triangles : $nt")
end

"""
    type == 1 => flip the edge
    type == 2 => split the edge
"""
function step!(env, triangle, vertex, type)
    if type == 1
        return step_flip!(env, triangle, vertex)
    elseif type == 2
        return step_split!(env, triangle, vertex)
    elseif type == 3
        return step_collapse!(env, triangle, vertex)
    else
        error("Expected type ∈ {1,2,3} got type = $type")
    end
end

function update_env_after_step!(env)
    env.vertex_score = env.mesh.degrees - env.d0
end

function step_flip!(env, triangle, vertex)
    success = false

    if is_valid_flip(env.mesh, triangle, vertex)
        @assert edgeflip!(env.mesh, triangle, vertex)
        update_env_after_step!(env)
        success = true
    end

    return success
end

function synchronize_desired_degree_size!(env)
    vertex_buffer_size = size(env.mesh.vertices, 2)
    if vertex_buffer_size > length(env.d0)
        num_new_vertices = vertex_buffer_size - length(env.d0)
        env.d0 = zero_pad(env.d0, num_new_vertices)
    end
end

function step_interior_split!(env, triangle, vertex;new_vertex_degree = 6)
    @assert has_neighbor(env.mesh, triangle, vertex)
    success = false

    if is_valid_interior_split(env.mesh, triangle, vertex)
        new_vertex_idx = env.mesh.new_vertex_pointer
        @assert split_interior_edge!(env.mesh, triangle, vertex)
        synchronize_desired_degree_size!(env)

        env.d0[new_vertex_idx] = new_vertex_degree
        update_env_after_step!(env)
        success = true
    end

    return success
end

function step_boundary_split!(env, triangle, vertex;new_vertex_degree = 4)

    @assert !has_neighbor(env.mesh, triangle, vertex)
    success = false

    if is_valid_boundary_split(env.mesh, triangle, vertex)
        new_vertex_idx = env.mesh.new_vertex_pointer
        @assert split_boundary_edge!(env.mesh, triangle, vertex)
        synchronize_desired_degree_size!(env)
        env.d0[new_vertex_idx] = new_vertex_degree
        update_env_after_step!(env)
        success = true
    end

    return success
end

function step_split!(env, triangle, vertex;new_interior_vertex_degree = 6, new_boundary_vertex_degree = 4)
    if has_neighbor(env.mesh, triangle, vertex)
        return step_interior_split!(env, triangle, vertex, new_vertex_degree = new_interior_vertex_degree)
    else
        return step_boundary_split!(env, triangle, vertex, new_vertex_degree = new_boundary_vertex_degree)
    end
end

function step_collapse!(env, triangle, vertex_idx)
    success = false
    if is_valid_collapse(env.mesh, triangle, vertex_idx)
        _, l2, l3 = next_cyclic_vertices(vertex_idx)
        v2, v3 = (vertex(env.mesh, l, triangle) for l in (l2, l3))
        env.d0[v2] = env.d0[v3]
        @assert collapse!(env.mesh, triangle, vertex_idx)
        update_env_after_step!(env)
        success = true
    end

    return success
end

function reindexed_desired_degree(old_desired_degree, new_vertex_indices, buffer_size)
    new_desired_degree = zeros(Int, buffer_size)
    for (old_idx, desired_degree) in enumerate(old_desired_degree)
        new_idx = new_vertex_indices[old_idx]
        if new_idx > 0
            new_desired_degree[new_idx] = desired_degree
        end
    end
    return new_desired_degree
end

function reindex!(env::GameEnv)
    reindex_triangles!(env.mesh)
    new_vertex_indices = reindex_vertices!(env.mesh)
    vertex_buffer_size = vertex_buffer(env.mesh)
    env.d0 = reindexed_desired_degree(env.d0, new_vertex_indices, vertex_buffer_size)
    env.vertex_score = env.mesh.degrees - env.d0
end