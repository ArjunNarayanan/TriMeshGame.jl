"""
    all_edges(t)

returns `edges,bndidx,emap` where
    `edges` [numedges,2] node connectivity. Each row is a pair of vertices
        that have an edge between them
    `bndidx` index of edges that are on the boundary (i.e. shared by only one triangle)
    `t2e` [numtriangles,3] index of edges that are opposite to the vertices in `t`.
        i.e. edges[emap[it,n],:] is the edge opposite to node `t[it,n]` in triangle `it`
"""
function all_edges(t)
    t = Array(transpose(t))
    edgemap = [2 3; 3 1; 1 2]
    etag = vcat(t[:, edgemap[1, :]], t[:, edgemap[2, :]], t[:, edgemap[3, :]])
    etag = hcat(sort(etag, dims = 2), 1:3*size(t, 1))
    etag = sortslices(etag, dims = 1)
    dup = all(etag[2:end, 1:2] - etag[1:end-1, 1:2] .== 0, dims = 2)[:]
    keep = .![false; dup]
    edges = etag[keep, 1:2]
    emap = cumsum(keep)
    invpermute!(emap, etag[:, 3])
    emap = reshape(emap, :, 3)
    dup = [dup; false]
    dup = dup[keep]
    # Edges that are not counted twice are boundary edges!
    bndix = findall(.!dup)

    emap = Array(transpose(emap))
    edges = Array(transpose(edges))

    return edges, bndix, emap
end

function boundary_nodes(edges, boundary_edges)
    return unique(vec(edges[:, boundary_edges]))
end

"""
    triangle_connectivity(t)

    returns `t2t,t2n` where
    `t2t` [3,numtriangles] triangle connectivity matrix. `t2t[n,it]` is the triangle adjacent
        to edge opposite node `n` in triangle `it`. 0 if there is no neighboring triangle.
    `t2n` [3,numtriangles] local index of node opposite shared edge in adjacent triangle.
        i.e. let `jt = t2t[n,it]` then `jt` and `it` share an edge. `t2n[n,it]` is the
        local index of the node in `jt` that is opposite the shared edge between `it` and `jt`.
        0 if there is no neighboring triangle.
"""
function triangle_connectivity(t, t2e)

    t = transpose(t)
    t2e = transpose(t2e)

    nt = size(t, 1)
    ts = [repeat(1:nt, 3) repeat(transpose(1:3), nt)[:]]

    ix = sortperm(t2e[:])
    jx = t2e[ix]
    ts = ts[ix, :]

    ix = findall(diff(jx) .== 0)
    # these are all the interior [triangle,edge] pairs per row
    ts1 = ts[ix, :]
    ts2 = ts[ix.+1, :]

    # for each [triangle,edge] which neighboring triangle am i connected to
    t2t = zeros(Int, nt, 3)
    t2t[ts1[:, 1].+nt*(ts1[:, 2].-1)] = ts2[:, 1]
    t2t[ts2[:, 1].+nt*(ts2[:, 2].-1)] = ts1[:, 1]

    # for each [triangle,edge] which edge in my neighboring triangle
    # am I connected to
    t2n = zeros(Int, nt, 3)
    t2n[ts1[:, 1].+nt*(ts1[:, 2].-1)] = ts2[:, 2]
    t2n[ts2[:, 1].+nt*(ts2[:, 2].-1)] = ts1[:, 2]

    t2t = Array(transpose(t2t))
    t2n = Array(transpose(t2n))

    t2t, t2n
end

function connect_triangle!(triangles, t2t, t2n, tri_idx)
    tri = triangles[tri_idx]
    for nbr_idx = 1:3
        nbr_id = t2t[nbr_idx, tri_idx]
        if nbr_id != 0
            set_neighbor!(tri, nbr_idx, triangles[nbr_id], t2n[nbr_idx, tri_idx])
        end
    end
end

function connect_triangles!(triangles, t2t, t2n)
    @assert size(t2t) == size(t2n)
    @assert length(triangles) == size(t2t, 2)

    for tri_idx = 1:size(t2t, 2)
        connect_triangle!(triangles, t2t, t2n, tri_idx)
    end
end

struct Mesh
    triangles::Vector{Triangle}
    vertices::Vector{Vertex}
    degrees::IdDict{Vertex,Int}
    vertex_on_boundary::IdDict{Vertex,Bool}
end

function triangles(m::Mesh)
    return m.triangles
end

function vertices(m::Mesh)
    return m.vertices
end

function degrees(m::Mesh)
    return m.degrees
end

function triangle(m::Mesh, i)
    return m.triangles[i]
end

function vertex(m::Mesh, i)
    return m.vertices[i]
end

function degree(m::Mesh, v::Vertex)
    return m.degrees[v]
end

function degree(m::Mesh, i)
    return degree(m, vertex(m, i))
end

function degree(m::Mesh, t::Triangle, i)
    return degree(m, vertex(t, i))
end

function vertex_on_boundary(m::Mesh, v::Vertex)
    return m.vertex_on_boundary[v]
end

function vertex_on_boundary(m::Mesh, t::Triangle, i)
    return vertex_on_boundary(m, vertex(t, i))
end

function Base.show(io::IO, m::Mesh)
    nt = length(triangles(m))
    println(io, "Mesh\n\t $nt triangles")
end

function vertex_degrees(edges, num_vertices)
    degree = zeros(Int, num_vertices)
    for e in eachcol(edges)
        degree[e] .+= 1
    end
    return degree
end


function Mesh(p::Matrix{Float64}, t::Matrix{Int})
    @assert size(p, 1) == 2
    @assert size(t, 1) == 3

    edges, boundary_edges, t2e = all_edges(t)
    t2t, t2n = triangle_connectivity(t, t2e)

    boundary_vertices = unique(vec(edges[:, boundary_edges]))
    on_boundary = falses(size(p, 2))
    on_boundary[boundary_vertices] .= true

    vertices = vec(mapslices(Vertex, p, dims = 1))
    d = vertex_degrees(edges, size(p, 2))
    degrees = IdDict(zip(vertices, d))
    vertex_on_boundary = IdDict(zip(vertices, on_boundary))

    triangles = [Triangle(vertices[v]) for v in eachcol(t)]
    connect_triangles!(triangles, t2t, t2n)

    return Mesh(triangles, vertices, degrees, vertex_on_boundary)
end