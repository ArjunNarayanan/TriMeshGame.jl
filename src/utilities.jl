function next(i)
    @assert i == 1 || i == 2 || i == 3
    return (i % 3) + 1
end

function previous(i)
    @assert i == 1 || i == 2 || i == 3
    return ((i + 1) % 3) + 1
end

function zero_pad(vec::Vector{T}, num_new_entries) where {T}
    return [vec; zeros(T, num_new_entries)]
end

function zero_pad(mat::Matrix{T}, num_new_cols) where {T}
    nr, nc = size(mat)
    return [mat zeros(T, nr, num_new_cols)]
end