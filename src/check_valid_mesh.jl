function all_active_vertices(mesh)
    conn = vec(mesh.connectivity)
    active_vertices = vcat(mesh.active_vertex, [true])
    conn[conn.==0] .= length(active_vertices)

    checks = active_vertices[conn]
    return all(checks)
end

function no_triangle_self_reference(mesh)
    for triangle in 1:triangle_buffer(mesh)
        if is_active_triangle(mesh, triangle)
            nbrs = mesh.t2t[:, triangle]
            if any(triangle .== nbrs)
                return false
            end
        end
    end
    return true
end

function all_active_triangle_or_boundary(mesh)
    for triangle in mesh.t2t
        if !(is_active_triangle_or_boundary(mesh, triangle))
            return false
        end
    end
    return true
end
