function make_template(mesh)
    nt = total_num_triangles(mesh)
    et = [mesh.t[tri,ver] for tri in 1:nt for ver in 1:3 if is_active_triangle(mesh,tri)]
    et = Array(reshape(et,1,:))
    return et
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

