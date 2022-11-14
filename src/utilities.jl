function next(i)
    @assert i == 1 || i == 2 || i == 3
    return (i % 3) + 1
end

function previous(i)
    @assert i == 1 || i == 2 || i == 3
    return ((i + 1) % 3) + 1
end

function zero_pad(vec::V, num_new_entries) where {V<:AbstractVector}
    T = eltype(vec)
    return [vec; zeros(T, num_new_entries)]
end

function zero_pad(mat::M, num_new_cols) where {M<:AbstractMatrix}
    nr, nc = size(mat)
    T = eltype(mat)
    return [mat zeros(T, nr, num_new_cols)]
end