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

    increment_degree!(m, v1)
    increment_degree!(m, v2)
    increment_degree!(m, v3)
    
    insert_vertex!(m, c, 3)

    delete_triangle!(m, T)

    insert_triangle!(m, newT1)
    insert_triangle!(m, newT2)
    insert_triangle!(m, newT3)
end

function split_interior_edge!(m, T, idx)
    @assert has_neighbor(T, idx)
    
    T1, T2, T3 = neighbor(T, idx), neighbor(T, next(idx)), neighbor(T, previous(idx))
    opp_idx = twin(T, idx)
    T4, T5 = neighbor(T1, next(opp_idx)), neighbor(T1, previous(opp_idx))

    v1, v2, v3 = vertex(T, idx), vertex(T, next(idx)), vertex(T, previous(idx))
    v4 = vertex(T1, opp_idx)

    new_vertex = 0.5*(v2 + v3)

    T6 = Triangle([new_vertex, v1, v2])
    T7 = Triangle([new_vertex, v2, v4])
    T8 = Triangle([new_vertex, v4, v3])
    T9 = Triangle([new_vertex, v3, v1])

    set_neighbor!(T6, 1, T3, twin(T, previous(idx)))
    set_neighbor!(T6, 2, T7, 3)
    set_neighbor!(T6, 3, T9, 2)

    set_neighbor!(T7, 1, T4, twin(T1, next(opp_idx)))
    set_neighbor!(T7, 2, T8, 3)
    set_neighbor!(T7, 3, T6, 2)

    set_neighbor!(T8, 1, T5, twin(T1, previous(opp_idx)))
    set_neighbor!(T8, 2, T9, 3)
    set_neighbor!(T8, 3, T7, 2)

    set_neighbor!(T9, 1, T2, twin(T, next(idx)))
    set_neighbor!(T9, 2, T6, 3)
    set_neighbor!(T9, 3, T8, 2)

    if !isnothing(T2) set_neighbor!(T2, twin(T, next(idx)), T9, 1) end
    if !isnothing(T3) set_neighbor!(T3, twin(T, previous(idx)), T6, 1) end
    if !isnothing(T4) set_neighbor!(T4, twin(T1, next(opp_idx)), T7, 1) end
    if !isnothing(T5) set_neighbor!(T5, twin(T1, previous(opp_idx)), T8, 1) end

    increment_degree!(m, v1)
    increment_degree!(m, v4)

    insert_vertex!(m, new_vertex, 4)

    delete_triangle!(m, T)
    delete_triangle!(m, T1)

    insert_triangle!(m, T6)
    insert_triangle!(m, T7)
    insert_triangle!(m, T8)
    insert_triangle!(m, T9)
end

function split!(m::Mesh, T::Triangle, idx)
    if has_neighbor(T, idx)
        split_interior_edge!(m, T, idx)
    else
        split_boundary_edge!(m, T, idx)
    end
end