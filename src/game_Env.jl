function make_template(mesh)
    pairs = make_edge_pairs(mesh)

    tri_vertices = reshape(mesh.t', 1, :)

    ct = cycle_edges(tri_vertices)

    p = zero_pad(tri_vertices)[:, pairs]
    cp1 = cycle_edges(p)

    p = zero_pad(cp1)[[2, 3], pairs]
    cp2 = cycle_edges(p)

    template = vcat(ct, cp1, cp2)

    return template
end

function make_edge_pairs(mesh)
    total_nt = total_num_triangles(mesh)
    pairs = zeros(Int, 3total_nt)
    nbr_idx = 3total_nt + 1
    for triangle = 1:total_nt
        for vertex = 1:3
            index = (triangle - 1) * 3 + vertex
            opp_tri, opp_ver = mesh.t2t[triangle, vertex], mesh.t2n[triangle, vertex]
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

    x = reshape(cat(x1, x2, x3, dims = 2), 3nf, :)
    return x
end

function zero_pad(m)
    return [m zeros(Int, size(m, 1))]
end

mutable struct GameEnv
    mesh::Mesh
    d0::Vector{Int}
    vertex_score::Vector{Int}
    template::Matrix{Int}
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
    mesh = deepcopy(mesh0)
    vertex_score = mesh.d - d0
    template = make_template(mesh)
    num_actions = 0
    initial_score = global_score(vertex_score)
    current_score = initial_score
    opt_score = optimum_score(vertex_score)
    reward = 0
    is_terminated = check_terminated(num_actions, max_actions, current_score, opt_score)
    GameEnv(
        mesh,
        copy(d0),
        vertex_score,
        template,
        max_actions,
        num_actions,
        initial_score,
        current_score,
        opt_score,
        reward,
        is_terminated,
    )
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
function step!(env, triangle, vertex, type; no_action_reward = -4)
    if type == 1
        step_flip!(env, triangle, vertex, no_action_reward)
    elseif type == 2
        step_split!(env, triangle, vertex, no_action_reward)
    else
        error("Expected type ∈ {1,2} got type = $type")
    end
end

function update_env_after_step!(env)
    env.vertex_score = env.mesh.d - env.d0
    env.template = make_template(env.mesh)
    env.current_score = global_score(env.vertex_score)
end

function step_flip!(env, triangle, vertex, no_action_reward)
    old_score = env.current_score
    if is_active_triangle(env.mesh, triangle) && isvalidflip(env.mesh, triangle, vertex)
        edgeflip!(env.mesh, triangle, vertex)

        update_env_after_step!(env)
        env.reward = old_score - env.current_score
    else
        env.reward = no_action_reward
    end
    env.num_actions += 1
    env.is_terminated = check_terminated(env)
end

function step_split!(env, triangle, vertex, no_action_reward; new_vertex_degree = 6)
    old_score = env.current_score
    if is_active_triangle(env.mesh,triangle) && has_neighbor(env.mesh, triangle, vertex)
        split_interior_edge!(env.mesh, triangle, vertex)
        
        push!(env.d0, new_vertex_degree)
        update_env_after_step!(env)
        env.reward = old_score - env.current_score
    else
        env.reward = no_action_reward
    end
    env.num_actions += 1
    env.is_terminated = check_terminated(env)
end

function step_split_allow_boundary!(env, triangle, vertex, no_action_reward, new_vertex_degree)
    old_score = env.current_score
    if is_active_triangle(env.mesh,triangle)
        if has_neighbor(env.mesh, triangle, vertex)
            split_interior_edge!(env.mesh, triangle, vertex)
        else
            split_boundary_edge!(env.mesh, triangle, vertex)
        end
        push!(env.d0, new_vertex_degree)
        update_env_after_step!(env)
        env.reward = old_score - env.current_score
    else
        env.reward = no_action_reward
    end
end