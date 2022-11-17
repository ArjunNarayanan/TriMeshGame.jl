function is_valid_interior_split(mesh, triangle, local_vertex_index; maxdegree = 9)
    if !is_active_triangle(mesh, triangle)
        return false
    end

    if !has_neighbor(mesh, triangle, local_vertex_index)
        return false
    end
    opp_tri = neighbor_triangle(mesh, local_vertex_index, triangle)
    opp_ver = neighbor_twin(mesh, local_vertex_index, triangle)

    if degree(mesh, vertex(mesh, local_vertex_index, triangle)) >= maxdegree ||
        degree(mesh, vertex(mesh, opp_ver, opp_tri)) >= maxdegree
        return false
    end

    return true
end

function new_vertex_coordinates(mesh, v1, v2)
    v1 = vertex_coordinates(mesh, v1)
    v2 = vertex_coordinates(mesh, v2)
    return 0.5*(v1+v2)
end

function split_interior_edge!(mesh, triangle, local_vertex_index; maxdegree = 9)
    if !is_valid_interior_split(mesh, triangle, local_vertex_index, maxdegree = maxdegree)
        return false
    end

    opp_tri, opp_ver = neighbor_triangle(mesh, local_vertex_index, triangle), neighbor_twin(mesh, local_vertex_index, triangle)

    T2 = neighbor_triangle(mesh, next(local_vertex_index), triangle)
    T3 = neighbor_triangle(mesh, previous(local_vertex_index), triangle)
    T4 = neighbor_triangle(mesh, next(opp_ver), opp_tri)
    T5 = neighbor_triangle(mesh, previous(opp_ver), opp_tri)

    v1 = vertex(mesh, local_vertex_index, triangle)
    v2 = vertex(mesh, next(local_vertex_index), triangle)
    v3 = vertex(mesh, opp_ver, opp_tri)
    v4 = vertex(mesh, previous(local_vertex_index), triangle)
    
    new_ver_coords = new_vertex_coordinates(mesh, v2, v4)
    
    new_ver_idx = insert_vertex!(mesh, new_ver_coords, 4, false)

    T6conn = [new_ver_idx, v1, v2]
    T7conn = [new_ver_idx, v2, v3]
    T8conn = [new_ver_idx, v3, v4]
    T9conn = [new_ver_idx, v4, v1]
    
    T6 = insert_triangle!(mesh, T6conn)
    T7 = insert_triangle!(mesh, T7conn)
    T8 = insert_triangle!(mesh, T8conn)
    T9 = insert_triangle!(mesh, T9conn)

    T6t2t = [T3, T7, T9]
    T7t2t = [T4, T8, T6]
    T8t2t = [T5, T9, T7]
    T9t2t = [T2, T6, T8]

    set_t2t!(mesh, T6, T6t2t)
    set_t2t!(mesh, T7, T7t2t)
    set_t2t!(mesh, T8, T8t2t)
    set_t2t!(mesh, T9, T9t2t)

    T6t2n = [neighbor_twin(mesh, previous(local_vertex_index), triangle), 3, 2]
    T7t2n = [neighbor_twin(mesh, next(opp_ver), opp_tri), 3, 2]
    T8t2n = [neighbor_twin(mesh, previous(opp_ver), opp_tri), 3, 2]
    T9t2n = [neighbor_twin(mesh, next(local_vertex_index), triangle), 3, 2]

    set_t2n!(mesh, T6, T6t2n)
    set_t2n!(mesh, T7, T7t2n)
    set_t2n!(mesh, T8, T8t2n)
    set_t2n!(mesh, T9, T9t2n)

    update_neighboring_triangle!(mesh, T6, 1)
    update_neighboring_triangle!(mesh, T7, 1)
    update_neighboring_triangle!(mesh, T8, 1)
    update_neighboring_triangle!(mesh, T9, 1)

    increment_degree!(mesh, v1)
    increment_degree!(mesh, v3)

    delete_triangle!(mesh, triangle)
    delete_triangle!(mesh, opp_tri)

    return true
end

function update_neighboring_triangle!(mesh, tri, ver)
    opp_tri, opp_ver = neighbor_triangle(mesh, ver, tri), neighbor_twin(mesh, ver, tri)

    if opp_tri != 0 && opp_ver != 0
        set_t2t!(mesh, opp_ver, opp_tri, tri)
        set_t2n!(mesh, opp_ver, opp_tri, ver)
    end
end

function is_valid_boundary_split(mesh, triangle, local_vertex_index; maxdegree = 9)
    if !is_active_triangle(mesh, triangle)
        return false
    end

    if has_neighbor(mesh, triangle, local_vertex_index)
        return false
    end

    if degree(mesh, vertex(mesh, local_vertex_index, triangle)) >= maxdegree
        return false
    end

    return true
end

function split_boundary_edge!(mesh, tri, ver)
    if !is_valid_boundary_split(mesh, tri, ver)
        return false
    end

    T1, T2 = neighbor_triangle(mesh, next(ver), tri), neighbor_triangle(mesh, previous(ver), tri)

    v1, v2, v3 = vertex(mesh, ver, tri), vertex(mesh, next(ver), tri), vertex(mesh, previous(ver), tri)
    
    new_ver_coords = new_vertex_coordinates(mesh, v2, v3)
    new_ver_idx = insert_vertex!(mesh, new_ver_coords, 3, true)

    T3conn = [new_ver_idx, v1, v2]
    T4conn = [new_ver_idx, v3, v1]

    T3 = insert_triangle!(mesh, T3conn)
    T4 = insert_triangle!(mesh, T4conn)

    T3t2t = [T2, 0, T4]
    T4t2t = [T1, T3, 0]

    set_t2t!(mesh, T3, T3t2t)
    set_t2t!(mesh, T4, T4t2t)

    T3t2n = [neighbor_twin(mesh, previous(ver), tri), 0, 2]
    T4t2n = [neighbor_twin(mesh, next(ver), tri), 3, 0]
    
    set_t2n!(mesh, T3, T3t2n)
    set_t2n!(mesh, T4, T4t2n)

    update_neighboring_triangle!(mesh, T3, 1)
    update_neighboring_triangle!(mesh, T4, 1)

    increment_degree!(mesh, v1)

    delete_triangle!(mesh, tri)

    return true
end