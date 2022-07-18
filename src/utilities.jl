function next(i)
    @assert i == 1 || i == 2 || i == 3
    return (i % 3) + 1
end

function previous(i)
    @assert i == 1 || i == 2 || i == 3
    return ((i + 1) % 3) + 1
end
