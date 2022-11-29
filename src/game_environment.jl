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
    max_actions::Any
    num_actions::Any
    initial_score::Any
    current_score::Any
    opt_score::Any
    reward::Any
    is_terminated::Any
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

function GameEnv(mesh0, d0, max_actions)
    @assert length(d0) == num_vertices(mesh0)
    @assert max_actions > 0

    mesh = deepcopy(mesh0)

    num_extra_vertices = vertex_buffer(mesh) - num_vertices(mesh)
    exp_d0 = zero_pad(d0, num_extra_vertices)

    vertex_score = mesh.degrees - exp_d0
    
    num_actions = 0
    initial_score = global_score(vertex_score)
    current_score = initial_score
    opt_score = optimum_score(vertex_score)
    reward = 0
    is_terminated = check_terminated(num_actions, max_actions, current_score, opt_score)
    GameEnv(
        mesh,
        exp_d0,
        vertex_score,
        max_actions,
        num_actions,
        initial_score,
        current_score,
        opt_score,
        reward,
        is_terminated,
    )
end

function active_vertex_score(env)
    return env.vertex_score[env.mesh.active_vertex]
end

function Base.show(io::IO, env::GameEnv)
    println(io, "GameEnv")
    println(io, "   num actions : $(env.num_actions)")
    println(io, "   max actions : $(env.max_actions)")
    println(io, "   score       : $(env.current_score)")
    println(io, "   opt score   : $(env.opt_score)")
    println(io, "   terminated  : $(env.is_terminated)")
end

"""
    type == 1 => flip the edge
    type == 2 => split the edge
"""
function step!(env, triangle, vertex, type; no_action_reward=-4)
    if type == 1
        return step_flip!(env, triangle, vertex, no_action_reward = no_action_reward)
    elseif type == 2
        return step_split!(env, triangle, vertex, no_action_reward = no_action_reward)
    elseif type == 3
        return step_collapse!(env, triangle, vertex, no_action_reward = no_action_reward)
    else
        error("Expected type ∈ {1,2,3} got type = $type")
    end
end

function update_env_after_step!(env)
    old_score = env.current_score
    env.vertex_score = env.mesh.degrees - env.d0
    env.current_score = global_score(env.vertex_score)
    env.reward = old_score - env.current_score
end

function pre_step_checks(env, triangle, vertex)
    @assert is_active_triangle(env.mesh, triangle)
    @assert !env.is_terminated
end

function post_step_updates!(env)
    env.num_actions += 1
    env.is_terminated = check_terminated(env)
end

function step_nothing!(env; reward = 0)
    env.reward = reward
    post_step_updates!(env)
end

function step_flip!(env, triangle, vertex; no_action_reward = -4)
    pre_step_checks(env, triangle, vertex)
    success = false

    if is_valid_flip(env.mesh, triangle, vertex)
        @assert edgeflip!(env.mesh, triangle, vertex)
        update_env_after_step!(env)
        success = true
    else
        env.reward = no_action_reward
    end
    post_step_updates!(env)

    return success
end

function synchronize_desired_degree_size!(env)
    vertex_buffer_size = size(env.mesh.vertices, 2)
    if vertex_buffer_size > length(env.d0)
        num_new_vertices = vertex_buffer_size - length(env.d0)
        env.d0 = zero_pad(env.d0, num_new_vertices)
    end
end

function step_interior_split!(env, triangle, vertex; no_action_reward = -4, new_vertex_degree = 6)
    pre_step_checks(env, triangle, vertex)

    @assert has_neighbor(env.mesh, triangle, vertex)
    success = false

    if is_valid_interior_split(env.mesh, triangle, vertex)
        new_vertex_idx = env.mesh.new_vertex_pointer

        @assert split_interior_edge!(env.mesh, triangle, vertex)
        synchronize_desired_degree_size!(env)

        env.d0[new_vertex_idx] = new_vertex_degree
        update_env_after_step!(env)
        success = true
    else
        env.reward = no_action_reward
    end
    post_step_updates!(env)

    return success
end

function step_boundary_split!(env, triangle, vertex; no_action_reward = -4, new_vertex_degree = 4)
    pre_step_checks(env, triangle, vertex)

    @assert !has_neighbor(env.mesh, triangle, vertex)
    success = false

    if is_valid_boundary_split(env.mesh, triangle, vertex)
        new_vertex_idx = env.mesh.new_vertex_pointer

        @assert split_boundary_edge!(env.mesh, triangle, vertex)
        synchronize_desired_degree_size!(env)

        env.d0[new_vertex_idx] = new_vertex_degree
        update_env_after_step!(env)
        success = true
    else
        env.reward = no_action_reward
    end
    post_step_updates!(env)

    return success
end

function step_split!(env, triangle, vertex; no_action_reward = -4, new_interior_vertex_degree = 6, new_boundary_vertex_degree = 4)
    if has_neighbor(env.mesh, triangle, vertex)
        return step_interior_split!(env, triangle, vertex, no_action_reward = no_action_reward, new_vertex_degree = new_interior_vertex_degree)
    else
        return step_boundary_split!(env, triangle, vertex, no_action_reward = no_action_reward, new_vertex_degree = new_boundary_vertex_degree)
    end
end

function step_collapse!(env, triangle, vertex_idx; no_action_reward = -4)
    pre_step_checks(env, triangle, vertex)

    success = false

    if is_valid_collapse(env.mesh, triangle, vertex_idx)
        _, l2, l3 = next_cyclic_vertices(vertex_idx)
        v2, v3 = (vertex(env.mesh, l, triangle) for l in (l2, l3))
        env.d0[v2] = env.d0[v3]
        
        @assert collapse!(env.mesh, triangle, vertex_idx)
        update_env_after_step!(env)
        success = true
    else
        env.reward = no_action_reward
    end
    post_step_updates!(env)

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
    env.edge_pairs = make_edge_pairs(env.mesh)
end