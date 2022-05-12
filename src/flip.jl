function isvalidflip(mesh::Mesh, tri::Triangle, ver; maxdegree = 9)
    if !has_neighbor(tri, ver)
        return false
    end

    opp_tri = neighbor(tri, ver)
    opp_ver = twin(tri, ver)

    if (degree(mesh, tri, ver) >= maxdegree) || (degree(mesh, opp_tri, opp_ver) >= maxdegree)
        return false
    end

    if (vertex_on_boundary(mesh, tri, next(ver)) && degree(mesh, tri, next(ver)) <= 2) ||
        (vertex_on_boundary(mesh, tri, previous(ver)) && degree(mesh, tri, previous(ver)) <= 2)
        return false
    end

    if (!vertex_on_boundary(mesh, tri, next(ver)) && degree(mesh, tri, next(ver)) <= 3) ||
        (!vertex_on_boundary(mesh, tri, previous(ver)) && degree(mesh, tri, previous(ver)) <= 3)
        return false
    end

    return true
end

function flip!(mesh::Mesh, tri::Triangle, ver)
    if isvalidflip(mesh, tri, ver)
        opp_tri = neighbor(tri, ver)
        opp_ver = twin(tri, ver)
        
        T1 = neighbor(tri, next(ver))
        T2 = neighbor(tri, previous(ver))
        T3 = neighbor(opp_tri, next(opp_ver))
        T4 = neighbor(opp_tri, previous(opp_ver))

        set_neighbor()
    end
end