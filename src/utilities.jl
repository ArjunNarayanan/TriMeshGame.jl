function next(i)
    @assert i == 1 || i == 2 || i == 3
    return (i % 3) + 1
end

function previous(i)
    @assert i == 1 || i == 2 || i == 3
    return ((i + 1) % 3) + 1
end

function pad(vec::V, num_new_entries, value) where {V <: AbstractVector}
    return [vec; fill(value, num_new_entries)]
end

function zero_pad(vec::V, num_new_entries) where {V<:AbstractVector}
    T = eltype(vec)
    return pad(vec, num_new_entries, zero(T))
end

function pad(mat::M, num_new_cols, value) where {M <: AbstractMatrix}
    nr, _ = size(mat)
    return [mat fill(value, (nr, num_new_cols))]
end

function zero_pad(mat::M, num_new_cols) where {M<:AbstractMatrix}
    T = eltype(mat)
    return pad(mat, num_new_cols, zero(T))
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
                    v1 = connectivity[next(edge), triangle]
                    v2 = connectivity[previous(edge), triangle]
                    new_points[:, v1] += points[:, v2]
                    new_points[:, v2] += points[:, v1]
                    count[v1] += 1
                    count[v2] += 1
                end
            end
        end
    end
    count[count .== 0] .= 1

    new_points = new_points ./ count'
    new_points[:, boundary_nodes] .= points[:, boundary_nodes]
    return new_points
end

function enclosed_angle(v1,v2)
    @assert length(v1) == length(v2) == 2
    dotp = dot(v1,v2)
    detp = v1[1]*v2[2] - v1[2]*v2[1]
    rad = atan(detp, dotp)
    if rad < 0
        rad += 2pi
    end

    return rad2deg(rad) 
end

function get_polygon_interior_angles(p)
    n = size(p,2)
    angles = zeros(n)
    for i = 1:n
        previ = i == 1 ? n : i -1
        nexti = i == n ? 1 : i + 1

        v1 = p[:,nexti] - p[:,i]
        v2 = p[:,previ] - p[:,i]
        angles[i] = enclosed_angle(v1,v2)
    end
    return angles
end

function rounded_desired_degree(angle, target_angle)
    degree = max(round(Int, angle/target_angle + 1), 2)
    return degree
end

function continuous_desired_degree(angle, target_angle)
    degree = max(angle/target_angle + 1.0, 2.0)
    return degree
end