function initialize_queue_with_boundary_edges(mesh)
    queue = Tuple{Int,Int}[]
    for triangle in 1:triangle_buffer(mesh)
        if is_active_triangle(mesh, triangle)
            for edge in 1:3
                if !has_neighbor(mesh, triangle, edge)
                    push!(queue, (triangle,edge))
                end
            end
        end
    end
    return queue
end

function initialize_distance_to_boundary(queue, mesh)
    distances = fill(-1, vertex_buffer(mesh))
    for (triangle,edge) in queue 
        vidx = vertex(mesh, next(edge), triangle)
        distances[vidx] = 0
    end
    return distances
end

function update_neighbor_distances!(triangle, edge, distances, queue, mesh)
    vidx = vertex(mesh, next(edge), triangle)
    new_distance = distances[vidx] + 1
    
    current_triangle = triangle
    current_edge = edge

    completed_spin = false
    is_boundary = false


    while !(completed_spin || is_boundary)
        current_edge = next(current_edge)

        vidx = vertex(mesh, next(current_edge), current_triangle)
        if distances[vidx] < 0
            distances[vidx] = new_distance
            push!(queue, (current_triangle, current_edge))
        end

        t, e = neighbor_triangle(mesh, next(current_edge), current_triangle), 
                neighbor_twin(mesh, next(current_edge), current_triangle)

        current_triangle = t
        current_edge = e

        completed_spin = current_triangle == triangle && current_edge == edge
        if current_triangle == 0
            @assert current_edge == 0
            is_boundary = true
        end
    end
end

function compute_distance_to_boundary(mesh)
    queue = initialize_queue_with_boundary_edges(mesh)
    distances = initialize_distance_to_boundary(queue, mesh)

    while length(queue) > 0
        triangle, edge = popfirst!(queue)
        update_neighbor_distances!(triangle, edge, distances, queue, mesh)
    end
    
    return distances
end