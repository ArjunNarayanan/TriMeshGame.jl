function centroid(vertices)
    coords = sum(coordinates.(vertices)) / length(vertices)
    return Vertex(coords)
end

function split!(m::Mesh, T::Triangle)
    c = centroid(vertices(T))

    T1, T2, T3 = neighbors(T)
    v1, v2, v3 = vertices(T)
    t1, t2, t3 = twin(T)

    newT1 = Triangle([c, v2, v3])
    newT2 = Triangle([c, v3, v1])
    newT3 = Triangle([c, v1, v2])

    set_neighbor!(newT1, 1, T1, t1)
    set_neighbor!(newT1, 2, newT2, 3)
    set_neighbor!(newT1, 3, newT3, 2)

    set_neighbor!(newT2, 1, T2, t2)
    set_neighbor!(newT2, 2, newT3, 3)
    set_neighbor!(newT2, 3, newT1, 2)

    set_neighbor!(newT3, 1, T3, t3)
    set_neighbor!(newT3, 2, newT1, 3)
    set_neighbor!(newT3, 3, newT2, 2)

    if !isnothing(T1) set_neighbor!(T1, t1, newT1, 1) end
    if !isnothing(T2) set_neighbor!(T2, t2, newT2, 1) end
    if !isnothing(T3) set_neighbor!(T3, t3, newT3, 1) end

    increment_degree(m, v1)
    increment_degree(m, v2)
    increment_degree(m, v3)
    
    insert_vertex!(m, c, 3)

    delete_triangle!(m, T)

    insert_triangle!(m, newT1)
    insert_triangle!(m, newT2)
    insert_triangle!(m, newT3)
end
