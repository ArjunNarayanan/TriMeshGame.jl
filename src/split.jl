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

function split_boundary_edge!(mesh, tri, ver)
    @assert !has_neighbor(mesh, tri, ver)
    @assert is_active_triangle(mesh, tri)

    nt, nv, ne = total_num_triangles(mesh), num_vertices(mesh), total_num_edges(mesh)

    T1, T2 = mesh.t2t[tri, next(ver)], mesh.t2t[tri, previous(ver)]

    v1, v2, v3 = mesh.t[tri, ver], mesh.t[tri, next(ver)], mesh.t[tri, previous(ver)]
    new_ver_coords = 0.5 * (mesh.p[v2, :] + mesh.p[v3, :])
    new_ver_idx = nv + 1
    insert_vertex!(mesh, new_ver_coords, 3, true)

    T3 = nt + 1
    T4 = nt + 2

    T3conn = [new_ver_idx, v1, v2]
    T4conn = [new_ver_idx, v3, v1]

    T3t2t = [T2, 0, T4]
    T4t2t = [T1, T3, 0]

    T3t2n = [mesh.t2n[tri, previous(ver)], 0, 2]
    T4t2n = [mesh.t2n[tri, next(ver)], 3, 0]

    T3t2e = [mesh.t2e[tri, previous(ver)], ne + 2, ne + 1]
    T4t2e = [mesh.t2e[tri, next(ver)], ne + 1, ne + 3]

    insert_triangle!(mesh, T3conn, T3t2t, T3t2n, T3t2e)
    insert_triangle!(mesh, T4conn, T4t2t, T4t2n, T4t2e)

    update_neighboring_triangle!(mesh, T3, 1)
    update_neighboring_triangle!(mesh, T4, 1)

    insert_edge!(mesh, new_ver_idx, v1, false)
    insert_edge!(mesh, new_ver_idx, v2, true)
    insert_edge!(mesh, new_ver_idx, v3, true)

    increment_degree!(mesh, v1)

    delete_triangle!(mesh, tri)

    delete_edge!(mesh, mesh.t2e[tri, ver])
end