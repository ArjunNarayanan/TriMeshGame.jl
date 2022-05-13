function next(i)
    @assert i == 1 || i == 2 || i == 3
    return (i%3) + 1
end

function previous(i)
    @assert i == 1 || i == 2 || i == 3
    return ((i+1)%3) + 1
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
    neighbors::Vector{Union{Triangle,Nothing}}
    twin::Vector{Int}
end

function Triangle(vertices)
    return Triangle(vertices, fill(nothing,3), zeros(Int,3))
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

function has_neighbor(t::Triangle, i)
    @assert i == 1 || i == 2 || i == 3
    return !isnothing(neighbor(t,i)) && twin(t, i) != 0
end

function twin(t::Triangle)
    t.twin
end

function twin(t::Triangle, i)
    return t.twin[i]
end

function set_neighbor!(t::Triangle, idx, neighbor, opp_vertex)
    t.neighbors[idx] = neighbor
    t.twin[idx] = opp_vertex
end

function set_neighbors!(t::Triangle, neighbors, opp_vertices)
    t.neighbors .= neighbors
    t.twin .= opp_vertices
end

function remove_neighbor!(t::Triangle, idx)
    t.neighbor[idx] = nothing
    t.twin[idx] = 0
end

function remove_neighbors!(t::Triangle)
    t.neighbors .= nothing
    t.twin .= 0
end

function set_vertex!(t::Triangle, idx, v)
    t.vertices[idx] = v
end