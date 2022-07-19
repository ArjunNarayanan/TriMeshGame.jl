function split_interior_edge!(m, tri, ver)
    @assert has_neighbor(m, tri, ver)
    @assert is_active_triangle(m, tri)

    nt, nv, ne = total_num_triangles(m), num_vertices(m), total_num_edges(m)

    opp_tri, opp_ver = m.t2t[tri, ver], m.t2n[tri, ver]

    T2 = m.t2t[tri, next(ver)]
    T3 = m.t2t[tri, previous(ver)]
    T4 = m.t2t[opp_tri, next(opp_ver)]
    T5 = m.t2t[opp_tri, previous(opp_ver)]

    v1, v2, v3, v4 = m.t[tri, ver], m.t[tri, next(ver)], m.t[opp_tri, opp_ver], m.t[tri, previous(ver)]
    new_ver_coords = 0.5 * (m.p[v2, :] + m.p[v4, :])
    new_ver_idx = nv + 1
    insert_vertex!(m, new_ver_coords, 4, false)

    T6 = nt + 1
    T7 = nt + 2
    T8 = nt + 3
    T9 = nt + 4

    T6conn = [new_ver_idx, v1, v2]
    T7conn = [new_ver_idx, v2, v3]
    T8conn = [new_ver_idx, v3, v4]
    T9conn = [new_ver_idx, v4, v1]

    T6t2t = [T3, T7, T9]
    T7t2t = [T4, T8, T6]
    T8t2t = [T5, T9, T7]
    T9t2t = [T2, T6, T8]

    T6t2n = [m.t2n[tri, previous(ver)], 3, 2]
    T7t2n = [m.t2n[opp_tri, next(opp_ver)], 3, 2]
    T8t2n = [m.t2n[opp_tri, previous(opp_ver)], 3, 2]
    T9t2n = [m.t2n[tri, next(ver)], 3, 2]

    T6t2e = [m.t2e[tri, previous(ver)], ne + 2, ne + 1]
    T7t2e = [m.t2e[opp_tri, next(opp_ver)], ne + 3, ne + 2]
    T8t2e = [m.t2e[opp_tri, previous(opp_ver)], ne + 4, ne + 3]
    T9t2e = [m.t2e[tri, next(ver)], ne + 1, ne + 4]

    insert_triangle!(m, T6conn, T6t2t, T6t2n, T6t2e)
    insert_triangle!(m, T7conn, T7t2t, T7t2n, T7t2e)
    insert_triangle!(m, T8conn, T8t2t, T8t2n, T8t2e)
    insert_triangle!(m, T9conn, T9t2t, T9t2n, T9t2e)

    update_neighboring_triangle!(m, T6, 1)
    update_neighboring_triangle!(m, T7, 1)
    update_neighboring_triangle!(m, T8, 1)
    update_neighboring_triangle!(m, T9, 1)

    insert_edge!(m, new_ver_idx, v1, false)
    insert_edge!(m, new_ver_idx, v2, false)
    insert_edge!(m, new_ver_idx, v3, false)
    insert_edge!(m, new_ver_idx, v4, false)

    increment_degree!(m, v1)
    increment_degree!(m, v3)

    delete_triangle!(m, tri)
    delete_triangle!(m, opp_tri)

    delete_edge!(m, m.t2e[tri, ver])
end

function update_neighboring_triangle!(m, tri, ver)
    opp_tri, opp_ver = m.t2t[tri, ver], m.t2n[tri, ver]
    if opp_tri != 0 && opp_ver != 0
        m.t2t[opp_tri, opp_ver] = tri
        m.t2n[opp_tri, opp_ver] = ver
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