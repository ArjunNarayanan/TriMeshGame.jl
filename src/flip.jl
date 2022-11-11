"""
    isvalidflip(m::Mesh, edgeix; maxdegree=9)

checks if a given edge can be flipped.
`edgeix` is a tuple `(t,j)` where `t` is a triangle idx, and `j ∈ {1,2,3}` is
a vertex in `t`. Returns true if the edge opposite to vertex `j` in triangle `t` can be flipped.
"""

function isvalidflip(mesh, triangle, vertex; maxdegree = 9)
    if !is_active_triangle(mesh, triangle)
        return false
    end

    # jt is the triangle adjacent to edge j in triangle it
    opp_tri = mesh.t2t[vertex, triangle]

    # jt = 0 implies we are trying to flip an edge on the boundary which
    # is not allowed, so we check jt > 0
    if opp_tri > 0
        @assert is_active_triangle(mesh, opp_tri)
        # k is the (local) index of the vertex opposite the shared edge
        # in the adjacent triangle
        opp_ver = mesh.t2n[vertex, triangle]

        # new triangle is constructed by taking:
        # vertex opposite to the edge we want to flip, then the next
        # cyclic vertex, then the vertex opposite the edge in the adjacent
        # triangle
        newt1 = (
            mesh.connectivity[vertex, triangle],
            mesh.connectivity[next(vertex), triangle],
            mesh.connectivity[opp_ver, opp_tri],
        )

        # new triangle is constructed by taking:
        # vertex opposite the edge in adjacent triangle, previous cyclic
        # vertex opposite edge in current triangle,
        # vertex opposite edge in current triangle
        newt2 = (
            mesh.connectivity[opp_ver, opp_tri],
            mesh.connectivity[previous(vertex), triangle],
            mesh.connectivity[vertex, triangle],
        )

        # Degree of the vertices newt1[1] and newt1[3] increases by 1,
        # so if it already has maxdegree, do not allow flip
        if mesh.degrees[newt1[1]] ≥ maxdegree || mesh.degrees[newt1[3]] ≥ maxdegree
            return false
        end

        # the first condition in the if seems redundant because you will not have a situation
        # were the node newt1[2] has degree less than 2 (otherwise you will not be able to flip it)
        # the second if condition is ensuring that interior nodes have a minimum degree of 3
        # which prevents triangles from inverting
        if (mesh.vertex_on_boundary[newt1[2]] && mesh.degrees[newt1[2]] ≤ 2) ||
           (!mesh.vertex_on_boundary[newt1[2]] && mesh.degrees[newt1[2]] ≤ 3) ||
           (mesh.vertex_on_boundary[newt2[2]] && mesh.degrees[newt2[2]] ≤ 2) ||
           (!mesh.vertex_on_boundary[newt2[2]] && mesh.degrees[newt2[2]] ≤ 3)
            return false
        end

        return true
    else
        return false
    end
end

function update_vertex_connectivity!(conn, tri, ver, opp_tri, opp_ver)
    newt1 = [conn[next(ver), tri], conn[opp_ver, opp_tri], conn[ver, tri]]
    newt1 = circshift(newt1, ver - 1)

    newt2 = [conn[next(opp_ver), opp_tri], conn[ver, tri], conn[opp_ver, opp_tri]]
    newt2 = circshift(newt2, opp_ver - 1)

    conn[:, tri] .= newt1
    conn[:, opp_tri] .= newt2
end

function update_vertex_degrees_after_flip!(
    mesh,
    tri,
    ver,
    opp_tri,
    opp_ver,
)
    increment_degree!(mesh, next(ver), tri)
    increment_degree!(mesh, previous(ver), tri)

    decrement_degree!(mesh, ver, tri)
    decrement_degree!(mesh, opp_ver, opp_tri)
end

function update_triangle_connectivity!(
    mesh,
    tri,
    ver,
    opp_tri,
    opp_ver,
)
    tri_conn = mesh.t2t
    newt2t1 =
        [opp_tri, tri_conn[previous(ver), tri], tri_conn[next(opp_ver), opp_tri]]
    newt2t1 = circshift(newt2t1, ver - 1)

    newt2t2 =
        [tri, tri_conn[previous(opp_ver), opp_tri], tri_conn[next(ver), tri]]
    newt2t2 = circshift(newt2t2, opp_ver - 1)

    set_t2t!(mesh, tri, newt2t1)
    set_t2t!(mesh, opp_tri, newt2t2)
end

function update_opposite_vertices!(
    mesh,
    tri,
    ver,
    opp_tri,
    opp_ver,
)
    opp_conn = mesh.t2n
    newt2n1 =
        [opp_ver, opp_conn[previous(ver), tri], opp_conn[next(opp_ver), opp_tri]]
    newt2n1 = circshift(newt2n1, ver - 1)

    newt2n2 =
        [ver, opp_conn[previous(opp_ver), opp_tri], opp_conn[next(ver), tri]]
    newt2n2 = circshift(newt2n2, opp_ver - 1)

    set_t2n!(mesh, tri, newt2n1)
    set_t2n!(mesh, opp_tri, newt2n2)
end

function update_neighboring_triangle_connectivity!(
    mesh,
    tri,
    ver,
    opp_tri,
    opp_ver,
)

    t = neighbor_triangle(mesh, next(ver), tri)
    v = neighbor_twin(mesh, next(ver), tri)
    set_neighbor_triangle_if_not_boundary!(mesh, v, t, tri)
    set_neighbor_twin_if_not_boundary!(mesh, v, t, next(ver))
    
    t = neighbor_triangle(mesh, previous(ver), tri)
    v = neighbor_twin(mesh, previous(ver), tri)
    set_neighbor_triangle_if_not_boundary!(mesh, v, t, tri)
    set_neighbor_twin_if_not_boundary!(mesh, v, t, previous(ver))
    
    t = neighbor_triangle(mesh, next(opp_ver), opp_tri)
    v = neighbor_twin(mesh, next(opp_ver), opp_tri)
    set_neighbor_triangle_if_not_boundary!(mesh, v, t, opp_tri)
    set_neighbor_twin_if_not_boundary!(mesh, v, t, next(opp_ver))
    
    t = neighbor_triangle(mesh, previous(opp_ver), opp_tri)
    v = neighbor_twin(mesh, previous(opp_ver), opp_tri)
    set_neighbor_triangle_if_not_boundary!(mesh, v, t, opp_tri)
    set_neighbor_twin_if_not_boundary!(mesh, v, t, previous(opp_ver))
end

function edgeflip!(mesh::Mesh, tri, ver; maxdegree = 9)

    if !isvalidflip(mesh, tri, ver, maxdegree = maxdegree)
        return false
    end
    # Edge opposite local vertex ver in triangle tri will be flipped

    # opp_tri is the triangle adjacent to tri sharing same edge
    opp_tri = mesh.t2t[ver, tri]

    # opp_ver is a vertex belonging in the adjacent triangle.
    # opp_ver is the vertex opposite edge being flipped.
    opp_ver = mesh.t2n[ver, tri]

    # connectivities of the new triangles being constructed (see comments in `isvalidflip` for
    # details on how the new triangles are constructed)
    # Maintain ordering so that flip can be reversed perfectly back to same state
    update_vertex_connectivity!(mesh.connectivity, tri, ver, opp_tri, opp_ver)

    # change the degree of the nodes which gained/lost an edge
    update_vertex_degrees_after_flip!(mesh, tri, ver, opp_tri, opp_ver)

    # construct the new triangle connectivities from the old connectivities
    # you can work this out geometrically if you draw the template for edgeflip
    # MAINTAIN ORDERING SO FLIP CAN BE REVERSED!
    update_triangle_connectivity!(
        mesh,
        tri,
        ver,
        opp_tri,
        opp_ver,
    )

    update_opposite_vertices!(mesh, tri, ver, opp_tri, opp_ver)

    # update the neighboring triangle connectivities
    update_neighboring_triangle_connectivity!(
        mesh,
        tri,
        ver,
        opp_tri,
        opp_ver,
    )

    return true
end
