function collapsed_vertex_degree(d1, d2)
    return d1 + d2 - 4
end

function is_valid_collapse(mesh, triangle_idx, vertex_idx; maxdegree = 9)
    if !is_active_triangle(mesh, triangle_idx)
        return false
    end

    if !has_neighbor(mesh, triangle_idx, vertex_idx)
        return false
    end

    lv1, lv2, lv3 = next_cyclic_vertices(vertex_idx)
    v1, v2, v3 = (vertex(mesh, lv, triangle_idx) for lv in (lv1, lv2, lv3))

    if vertex_on_boundary(mesh, v2) && vertex_on_boundary(mesh, v3)
        return false
    end

    d1, d2, d3 = degree(mesh, v1), degree(mesh, v2), degree(mesh, v3)
    if (!vertex_on_boundary(mesh, v1)) && (d1 <= 3)
        return false
    end

    new_degree = collapsed_vertex_degree(d2, d3)
    if new_degree > maxdegree
        return false
    end

    return true
end

function collapsed_vertex_coordinates(mesh, v1, v2)
    @assert !(vertex_on_boundary(mesh, v1) && vertex_on_boundary(mesh, v2))
    if vertex_on_boundary(mesh, v1)
        return vertex_coordinates(mesh, v1)
    elseif vertex_on_boundary(mesh, v2)
        return vertex_coordinates(mesh, v2)
    else
        return 0.5*(vertex_coordinates(mesh, v1) + vertex_coordinates(mesh, v2))
    end
end

function collapse!(mesh, triangle_idx, vertex_idx; maxdegree = 9)
    if !is_valid_collapse(mesh, triangle_idx, vertex_idx, maxdegree = maxdegree)
        return false
    end

    l1, l2, l3 = next_cyclic_vertices(vertex_idx)
    v1, v2, v3 = (vertex(mesh, l, triangle_idx) for l in (l1, l2, l3))

    new_coords = collapsed_vertex_coordinates(mesh, v2, v3)
    new_degree = collapsed_vertex_degree(degree(mesh, v2), degree(mesh, v3))
    
    set_vertex_coordinates!(mesh, v2, new_coords)
    set_degree!(mesh, v2, new_degree)
    
    if vertex_on_boundary(mesh, v3)
        set_vertex_on_boundary!(mesh, v2, true)
    end

    replace_index_in_connectivity(mesh, v3, v2)

    T1, T2, T3 = (neighbor_triangle(mesh, l, triangle_idx) for l in (l1, l2, l3))
    ol1, ol2, ol3 = (neighbor_twin(mesh, l, triangle_idx) for l in (l1, l2, l3))

    set_neighbor_triangle_if_not_boundary!(mesh, ol2, T2, T3)
    set_neighbor_triangle_if_not_boundary!(mesh, ol3, T3, T2)
    
    set_neighbor_twin_if_not_boundary!(mesh, ol2, T2, ol3)
    set_neighbor_twin_if_not_boundary!(mesh, ol3, T3, ol2)

    nbr_triangle = T1
    nbr_twin = ol1
    l4, l5, l6 = next_cyclic_vertices(nbr_twin)
    T4, T5, T6 = (neighbor_triangle(mesh, l, nbr_triangle) for l in (l4, l5, l6))
    ol4, ol5, ol6 = (neighbor_twin(mesh, l, nbr_triangle) for l in (l4, l5, l6))

    set_neighbor_triangle_if_not_boundary!(mesh, ol5, T5, T6)
    set_neighbor_triangle_if_not_boundary!(mesh, ol6, T6, T5)

    set_neighbor_twin_if_not_boundary!(mesh, ol5, T5, ol6)
    set_neighbor_twin_if_not_boundary!(mesh, ol6, T6, ol5)

    v4 = vertex(mesh, nbr_twin, nbr_triangle)
    decrement_degree!(mesh, v1)
    decrement_degree!(mesh, v4)

    delete_vertex!(mesh, v3)
    delete_triangle!(mesh, triangle_idx)
    delete_triangle!(mesh, nbr_triangle)

    return true
end