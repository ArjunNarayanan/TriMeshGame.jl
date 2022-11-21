function next(i)
    @assert i == 1 || i == 2 || i == 3
    return (i % 3) + 1
end

function previous(i)
    @assert i == 1 || i == 2 || i == 3
    return ((i + 1) % 3) + 1
end

function zero_pad(vec::V, num_new_entries) where {V<:AbstractVector}
    T = eltype(vec)
    return [vec; zeros(T, num_new_entries)]
end

function zero_pad(mat::M, num_new_cols) where {M<:AbstractMatrix}
    nr, nc = size(mat)
    T = eltype(mat)
    return [mat zeros(T, nr, num_new_cols)]
end

function next_cyclic_vertices(v1)
    v2 = next(v1)
    v3 = next(v2)
    return v1, v2, v3
end

function averagesmoothing(points, connectivity, t2t, active_triangles, boundary_nodes)
    num_points = size(points, 2)
    new_points = similar(points)
    fill!(new_points, 0.0)
    count = zeros(Int, num_points)

    for (triangle, is_active) in enumerate(active_triangles)
        if is_active
            for edge in 1:3
                if triangle > t2t[edge, triangle]
                    v1 = connectivity[edge, triangle]
                    v2 = connectivity[next(edge), triangle]
                    new_points[:,v1] += points[:, v2]
                    new_points[:, v2] += points[:, v1]
                    count[v1] += 1
                    count[v2] += 1
                end
            end
        end
    end
    count[count .== 0] .= 1
    new_points = new_points ./ count'
    new_points[:, boundary_nodes] = points[:, boundary_nodes]
    return new_points
end