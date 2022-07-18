function split_interior_edge!(m, tri, ver)
    @assert has_neighbor(m, tri, ver)

    nt, nv, ne = total_num_triangles(m), num_vertices(m), total_num_edges(m)
    
    opp_tri, opp_ver = m.t2t[tri,ver], m.t2n[tri,ver]

    T2 = m.t2t[tri, next(ver)]
    T3 = m.t2t[tri, previous(ver)]
    T4 = m.t2t[opp_tri, next(opp_ver)]
    T5 = m.t2t[opp_tri, previous(opp_ver)]

    v1, v2, v3, v4 = m.t[tri,ver], m.t[tri, next(ver)], m.t[opp_tri,opp_ver], m.t[tri, previous(ver)]
    new_ver_coords = 0.5*(m.p[v2,:] + m.p[v4,:])
    new_ver_idx = nv + 1
    insert_vertex!(m, new_ver_coords, 4, false)

    T6 = nt+1
    T7 = nt+2
    T8 = nt+3
    T9 = nt+4

    T6conn = [new_ver_idx,v1,v2]
    T7conn = [new_ver_idx,v2,v3]
    T8conn = [new_ver_idx,v3,v4]
    T9conn = [new_ver_idx,v4,v1]

    T6t2t = [T3, T7, T9]
    T7t2t = [T4, T8, T6]
    T8t2t = [T5, T9, T7]
    T9t2t = [T2, T6, T8]

    T6t2n = [m.t2n[tri, previous(ver)], 3, 2]
    T7t2n = [m.t2n[opp_tri, next(opp_ver)], 3, 2]
    T8t2n = [m.t2n[opp_tri, previous(opp_ver)], 3, 2]
    T9t2n = [m.t2n[tri, next(ver)], 3, 2]

    T6t2e = [m.t2e[tri, previous(ver)], ne+2, ne+1]
    T7t2e = [m.t2e[opp_tri, next(opp_ver)], ne+3, ne+2]
    T8t2e = [m.t2e[opp_tri, previous(opp_ver)], ne+4, ne+3]
    T9t2e = [m.t2e[tri, next(ver)], ne+1, ne+4]

    insert_triangle!(m, T6conn, T6t2t, T6t2n, T6t2e)
    insert_triangle!(m, T7conn, T7t2t, T7t2n, T7t2e)
    insert_triangle!(m, T8conn, T8t2t, T8t2n, T8t2e)
    insert_triangle!(m, T9conn, T9t2t, T9t2n, T9t2e)
    
    update_neighboring_triangle!(m, T6, 1)
    update_neighboring_triangle!(m, T7, 1)
    update_neighboring_triangle!(m, T8, 1)
    update_neighboring_triangle!(m, T9, 1)

    insert_edge!(m, new_ver_idx, v1)
    insert_edge!(m, new_ver_idx, v2)
    insert_edge!(m, new_ver_idx, v3)
    insert_edge!(m, new_ver_idx, v4)

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