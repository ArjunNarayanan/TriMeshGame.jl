"""
    isvalidflip(m::Mesh, edgeix; maxdegree=9)

checks if a given edge can be flipped.
`edgeix` is a tuple `(t,j)` where `t` is a triangle idx, and `j ∈ {1,2,3}` is
a vertex in `t`. Returns true if the edge opposite to vertex `j` in triangle `t` can be flipped.
"""

function isvalidflip(m::Mesh, triangle, vertex; maxdegree = 9)
    if !is_active_triangle(m, triangle)
        return false
    end

    # jt is the triangle adjacent to edge j in triangle it
    opp_tri = m.t2t[triangle, vertex]
    valid_flip = false

    # jt = 0 implies we are trying to flip an edge on the boundary which
    # is not allowed, so we check jt > 0
    if opp_tri > 0
        # k is the (local) index of the vertex opposite the shared edge
        # in the adjacent triangle
        opp_ver = m.t2n[triangle, vertex]

        # new triangle is constructed by taking:
        # vertex opposite to the edge we want to flip, then the next
        # cyclic vertex, then the vertex opposite the edge in the adjacent
        # triangle
        newt1 = (
            m.t[triangle, vertex],
            m.t[triangle, next(vertex)],
            m.t[opp_tri, opp_ver],
        )

        # new triangle is constructed by taking:
        # vertex opposite the edge in adjacent triangle, previous cyclic
        # vertex opposite edge in current triangle,
        # vertex opposite edge in current triangle
        newt2 = (
            m.t[opp_tri, opp_ver],
            m.t[triangle, previous(vertex)],
            m.t[triangle, vertex],
        )

        valid_flip = true

        # Degree of the vertices newt1[1] and newt1[3] increases by 1,
        # so if it already has maxdegree, do not allow flip
        if m.d[newt1[1]] ≥ maxdegree || m.d[newt1[3]] ≥ maxdegree
            valid_flip = false
        end

        # the first condition in the if seems redundant because you will not have a situation
        # were the node newt1[2] has degree less than 2 (otherwise you will not be able to flip it)
        # the second if condition is ensuring that interior nodes have a minimum degree of 3
        # which prevents triangles from inverting
        if (m.vertex_on_boundary[newt1[2]] && m.d[newt1[2]] ≤ 2) ||
           (!m.vertex_on_boundary[newt1[2]] && m.d[newt1[2]] ≤ 3) ||
           (m.vertex_on_boundary[newt2[2]] && m.d[newt2[2]] ≤ 2) ||
           (!m.vertex_on_boundary[newt2[2]] && m.d[newt2[2]] ≤ 3)
            valid_flip = false
        end
    end
    return valid_flip
end

function update_vertex_connectivity!(conn, tri, ver, opp_tri, opp_ver)
    newt1 = [conn[tri, next(ver)], conn[opp_tri, opp_ver], conn[tri, ver]]
    newt1 = circshift(newt1, ver - 1)

    newt2 = [conn[opp_tri, next(opp_ver)], conn[tri, ver], conn[opp_tri, opp_ver]]
    newt2 = circshift(newt2, opp_ver - 1)

    conn[tri, :] .= newt1
    conn[opp_tri, :] .= newt2
end

function update_edge_connectivity!(edges, conn, edgeid, tri, ver)
    node1 = conn[tri, next(ver)]
    node2 = conn[tri, previous(ver)]
    edges[edgeid, 1] = min(node1, node2)
    edges[edgeid, 2] = max(node1, node2)
end

function update_vertex_degrees!(
    degrees,
    conn,
    tri,
    ver,
    opp_tri,
    opp_ver,
)
    degrees[conn[tri, next(ver)]] += 1
    degrees[conn[tri, previous(ver)]] += 1
    degrees[conn[tri, ver]] -= 1
    degrees[conn[opp_tri, opp_ver]] -= 1
end

function update_triangle_connectivity!(
    tri_conn,
    tri,
    ver,
    opp_tri,
    opp_ver,
)
    newt2t1 =
        [opp_tri, tri_conn[tri, previous(ver)], tri_conn[opp_tri, next(opp_ver)]]
    newt2t1 = circshift(newt2t1, ver - 1)

    newt2t2 =
        [tri, tri_conn[opp_tri, previous(opp_ver)], tri_conn[tri, next(ver)]]
    newt2t2 = circshift(newt2t2, opp_ver - 1)

    tri_conn[tri, :] .= newt2t1
    tri_conn[opp_tri, :] .= newt2t2

end

function update_opposite_vertices!(
    opp_conn,
    tri,
    ver,
    opp_tri,
    opp_ver,
)
    newt2n1 =
        [opp_ver, opp_conn[tri, previous(ver)], opp_conn[opp_tri, next(opp_ver)]]
    newt2n1 = circshift(newt2n1, ver - 1)

    newt2n2 =
        [ver, opp_conn[opp_tri, previous(opp_ver)], opp_conn[tri, next(ver)]]
    newt2n2 = circshift(newt2n2, opp_ver - 1)

    opp_conn[tri, :] .= newt2n1
    opp_conn[opp_tri, :] .= newt2n2

end

function update_opposite_edges!(
    opp_edges,
    tri,
    ver,
    opp_tri,
    opp_ver,
)
    edgeid = opp_edges[tri, ver]

    newt2e1 =
        [edgeid, opp_edges[tri, previous(ver)], opp_edges[opp_tri, next(opp_ver)]]
    newt2e1 = circshift(newt2e1, ver - 1)

    newt2e2 =
        [edgeid, opp_edges[opp_tri, previous(opp_ver)], opp_edges[tri, next(ver)]]
    newt2e2 = circshift(newt2e2, opp_ver - 1)

    opp_edges[tri, :] .= newt2e1
    opp_edges[opp_tri, :] .= newt2e2
end

function update_neighboring_triangle_connectivity!(
    tri_conn,
    opp_conn,
    tri,
    ver,
    opp_tri,
    opp_ver,
)

    t = tri_conn[tri, next(ver)]
    v = opp_conn[tri, next(ver)]
    if t > 0
        tri_conn[t, v] = tri
        opp_conn[t, v] = next(ver)
    end

    t = tri_conn[tri, previous(ver)]
    v = opp_conn[tri, previous(ver)]
    if t > 0
        tri_conn[t, v] = tri
        opp_conn[t, v] = previous(ver)
    end

    t = tri_conn[opp_tri, next(opp_ver)]
    v = opp_conn[opp_tri, next(opp_ver)]
    if t > 0
        tri_conn[t, v] = opp_tri
        opp_conn[t, v] = next(opp_ver)
    end

    t = tri_conn[opp_tri, previous(opp_ver)]
    v = opp_conn[opp_tri, previous(opp_ver)]
    if t > 0
        tri_conn[t, v] = opp_tri
        opp_conn[t, v] = previous(opp_ver)
    end
end

function edgeflip!(m::Mesh, tri, ver; maxdegree = 9)

    if !isvalidflip(m, tri, ver, maxdegree = maxdegree)
        return false
    end
    # Edge opposite local vertex ver in triangle tri will be flipped

    # opp_tri is the triangle adjacent to tri sharing same edge
    opp_tri = m.t2t[tri, ver]

    # opp_ver is a vertex belonging in the adjacent triangle.
    # opp_ver is the vertex opposite edge being flipped.
    opp_ver = m.t2n[tri, ver]

    # e is the index of the edge being flipped
    edgeid = m.t2e[tri, ver]

    # connectivities of the new triangles being constructed (see comments in `isvalidflip` for
    # details on how the new triangles are constructed)
    # Maintain ordering so that flip can be reversed perfectly back to same state
    update_vertex_connectivity!(m.t, tri, ver, opp_tri, opp_ver)

    # Update the end points of the edge that was flipped
    update_edge_connectivity!(m.edges, m.t, edgeid, tri, ver)

    # change the degree of the nodes which gained/lost an edge
    update_vertex_degrees!(m.d, m.t, tri, ver, opp_tri, opp_ver)

    # construct the new triangle connectivities from the old connectivities
    # you can work this out geometrically if you draw the template for edgeflip
    # MAINTAIN ORDERING SO FLIP CAN BE REVERSED!
    update_triangle_connectivity!(
        m.t2t,
        tri,
        ver,
        opp_tri,
        opp_ver,
    )

    update_opposite_vertices!(m.t2n, tri, ver, opp_tri, opp_ver)

    update_opposite_edges!(m.t2e, tri, ver, opp_tri, opp_ver)

    # update the neighboring triangle connectivities
    update_neighboring_triangle_connectivity!(
        m.t2t,
        m.t2n,
        tri,
        ver,
        opp_tri,
        opp_ver,
    )

    return true
end
