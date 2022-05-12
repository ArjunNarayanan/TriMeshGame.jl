function centroid(vertices)
    coords = sum(coordinates.(vertices)) / length(vertices)
    return Vertex(coords)
end

function split!(m::Mesh, T::Triangle)
    c = centroid(vertices(T))
end