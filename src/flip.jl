function isvalidflip(mesh::Mesh, tri::Triangle, ver; maxdegree = 9)
    if !has_neighbor(tri, ver)
        return false
    end

    opp_tri = neighbor(tri, ver)
    opp_ver = twin(tri, ver)

    if (degree(mesh, tri, ver) >= maxdegree) ||
       (degree(mesh, opp_tri, opp_ver) >= maxdegree)
        return false
    end

    if (vertex_on_boundary(mesh, tri, next(ver)) && degree(mesh, tri, next(ver)) <= 2) || (
        vertex_on_boundary(mesh, tri, previous(ver)) &&
        degree(mesh, tri, previous(ver)) <= 2
    )
        return false
    end

    if (!vertex_on_boundary(mesh, tri, next(ver)) && degree(mesh, tri, next(ver)) <= 3) || (
        !vertex_on_boundary(mesh, tri, previous(ver)) &&
        degree(mesh, tri, previous(ver)) <= 3
    )
        return false
    end

    return true
end

function update_triangle_vertices!(tri, ver, opp_tri, opp_ver)
    v1 = vertex(tri, ver)
    v2 = vertex(tri, next(ver))
    v3 = vertex(opp_tri, opp_ver)
    v4 = vertex(opp_tri, next(opp_ver))

    set_vertex!(tri, previous(ver), v1)
    set_vertex!(tri, ver, v2)
    set_vertex!(tri, next(ver), v3)

    set_vertex!(opp_tri, previous(opp_ver), v3)
    set_vertex!(opp_tri, opp_ver, v4)
    set_vertex!(opp_tri, next(opp_ver), v1)
end

function update_triangle_connectivity!(tri, ver, opp_tri, opp_ver)
    T1 = neighbor(tri, next(ver))
    v1 = twin(tri, next(ver))

    T2 = neighbor(tri, previous(ver))
    v2 = twin(tri, previous(ver))

    T3 = neighbor(opp_tri, next(opp_ver))
    v3 = twin(opp_tri, next(opp_ver))

    T4 = neighbor(opp_tri, previous(opp_ver))
    v4 = twin(opp_tri, previous(opp_ver))

    set_neighbor!(tri, next(ver), T2, v2)
    set_neighbor!(tri, previous(ver), T3, v3)

    set_neighbor!(opp_tri, next(opp_ver), T4, v4)
    set_neighbor!(opp_tri, previous(opp_ver), T1, v1)

    if !isnothing(T1)
        set_neighbor!(T1, v1, opp_tri, previous(opp_ver))
    end
    if !isnothing(T2)
        set_neighbor!(T2, v2, tri, next(ver))
    end
    if !isnothing(T3)
        set_neighbor!(T3, v3, tri, previous(ver))
    end
    if !isnothing(T4)
        set_neighbor!(T4, v4, opp_tri, next(opp_ver))
    end
end

function update_vertex_degrees!(mesh, tri, ver, opp_tri, opp_ver)
    increment_degree(mesh, tri, ver)
    increment_degree(mesh, opp_tri, opp_ver)

    decrement_degree(mesh, tri, next(ver))
    decrement_degree(mesh, tri, previous(ver))
end

function flip!(mesh::Mesh, tri::Triangle, ver)
    if !isvalidflip(mesh, tri, ver)
        return false
    else
        opp_tri = neighbor(tri, ver)
        opp_ver = twin(tri, ver)

        update_vertex_degrees!(mesh, tri, ver, opp_tri, opp_ver)
        update_triangle_vertices!(tri, ver, opp_tri, opp_ver)
        update_triangle_connectivity!(tri, ver, opp_tri, opp_ver)

        return true
    end
end
