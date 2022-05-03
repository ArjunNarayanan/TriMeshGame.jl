function next(i)
    if i == 1
        return 2
    elseif i == 2
        return 3
    elseif i == 3
        return 1
    else
        error("Expected i = 1, 2, 3. Got i = $i")
    end
end

function previous(i)
    if i == 1
        return 3
    elseif i == 2
        return 1
    elseif i == 3
        return 2
    else
        error("Expected i = 1, 2, 3. Got i = $i")
    end
end

struct Vertex
    coordinates::Vector{Float64}
end

function coordinates(v::Vertex)
    return v.coordinates
end

function Base.show(io::IO, v::Vertex)
    c = coordinates(v)
    @assert length(c) == 2 "Only 2D points allowed"
    s = @sprintf "Vertex\n\t(%1.3f  %1.3f)" c[1] c[2]
    println(io, s)
end

struct Triangle
    vertices::Vector{Vertex}
    neighbors::Vector{Triangle}
    twin::Vector{Int}
end

function Triangle(vertices)
    return Triangle(vertices, Vector{Triangle}(undef, 3), [0, 0, 0])
end

function Base.show(io::IO, t::Triangle)
    println(io, "Triangle")
end

function vertices(t::Triangle)
    t.vertices
end

function vertex(t::Triangle, i)
    t.vertices[i]
end

function neighbors(t::Triangle)
    t.neighbors
end

function neighbor(t::Triangle, i)
    return t.neighbors[i]
end

function twin(t::Triangle)
    t.twin
end

function twin(t::Triangle, i)
    return t.twin[i]
end

function set_neighbor!(t::Triangle, idx, neighbor::Triangle, opp_vertex)
    t.neighbors[idx] = neighbor
    t.twin[idx] = opp_vertex
end

function set_neighbors!(t::Triangle, neighbors::Vector{Triangle}, opp_vertices)
    t.neighbors .= neighbors
    t.twin .= opp_vertices
end