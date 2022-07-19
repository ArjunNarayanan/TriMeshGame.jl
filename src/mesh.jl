"""
    all_edges(t)

returns `edges,bndidx,emap` where
    `edges` [numedges,2] node connectivity. Each row is a pair of vertices
        that have an edge between them
    `bndidx` index of edges that are on the boundary (i.e. shared by only one triangle)
    `emap` [numtriangles,3] index of edges that are opposite to the vertices in `t`.
        i.e. edges[emap[it,n],:] is the edge opposite to node `t[it,n]` in triangle `it`
"""
function all_edges(t)
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
    return edges, bndix, emap
end

"""
    triangle_connectivity(t)

    returns `t2t,t2n` where
    `t2t` [numtriangles,3] triangle connectivity matrix. `t2t[it,n]` is the triangle adjacent
        to edge opposite node `n` in triangle `it`. 0 if there is no neighboring triangle.
    `t2n` [numtriangles,3] local index of node opposite shared edge in adjacent triangle.
        i.e. let `jt = t2t[it,n]` then `jt` and `it` share an edge. `t2n[it,n]` is the
        local index of the node in `jt` that is opposite the shared edge between `it` and `jt`.
        0 if there is no neighboring triangle.
"""
function triangle_connectivity(t, t2e)
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

    t2t, t2n
end

function boundary_vertices(edges, boundary_edges)
    return unique(vec(edges[boundary_edges, :]))
end

function vertex_degrees(edges, num_vertices)
    d = zeros(Int, num_vertices)
    for i = 1:size(edges, 1)
        d[edges[i, [1, 2]]] .+= 1
    end
    return d
end

"""
    Mesh

`p` - [x,y] coordinates of nodes
`t` - [numtriangles,3] node connectivity of each triangle
`edges` - [numedges,2] edge connectivity
`t2t` - [numtriangles,3] triangle connectivity (i.e. neighboring triangle ID)
        `t2t[j,t]` is the triangle adjacent to the edge opposite to vertex `j`
        in triangle `t`
`t2n` - [numtriangles,3] vertex opposite shared edge in neighboring triangle
`t2e` - [numtriangles,3] index of edge opposite a given triangle vertex
`d` - degree of each vertex (i.e how many edges incident on vertex)
`bnd_nodes` - nodeids on the boundary
`boundary_edges` - index of edges on the boundary
`node_on_bnd` - true/false if node on boundary
"""
mutable struct Mesh
    p::Matrix{Float64}
    t::Matrix{Int64}
    edges::Matrix{Int64}
    t2t::Matrix{Int64}
    t2n::Matrix{Int64}
    t2e::Matrix{Int64}

    d::Vector{Int64}
    vertex_on_boundary::Vector{Bool}
    edge_on_boundary::Vector{Bool}

    active_triangle::Vector{Bool}
    active_edge::Vector{Bool}

    num_vertices::Int
    num_edges::Int
    num_triangles::Int

    function Mesh(p, t)
        edges, boundary_edges, t2e = all_edges(t)
        t2t, t2n = triangle_connectivity(t, t2e)

        num_edges = size(edges, 1)
        num_triangles = size(t, 1)
        num_vertices = size(p, 1)

        edge_on_boundary = falses(num_edges)
        edge_on_boundary[boundary_edges] .= true

        boundary_vertex = boundary_vertices(edges, boundary_edges)
        vertex_on_boundary = falses(num_vertices)
        vertex_on_boundary[boundary_vertex] .= true

        degrees = vertex_degrees(edges, num_vertices)

        active_triangle = trues(num_triangles)
        active_edge = trues(num_edges)


        return new(
            p,
            t,
            edges,
            t2t,
            t2n,
            t2e,
            degrees,
            vertex_on_boundary,
            edge_on_boundary,
            active_triangle,
            active_edge,
            num_vertices,
            num_edges,
            num_triangles,
        )
    end
end

function num_vertices(m::Mesh)
    return m.num_vertices
end

function num_edges(m::Mesh)
    return m.num_edges
end

function total_num_edges(m::Mesh)
    return size(m.edges, 1)
end

function num_triangles(m::Mesh)
    return m.num_triangles
end

function total_num_triangles(m::Mesh)
    return size(m.t, 1)
end

function has_neighbor(m::Mesh, tri, ver)
    if !is_active_triangle(m, tri)
        @warn "Triangle $tri is not active"
    end
    return m.t2t[tri,ver] != 0
end

function Base.show(io::IO, m::Mesh)
    println(io, "Mesh:")
    println(io, "  " * string(num_vertices(m)) * " vertices")
    println(io, "  " * string(num_triangles(m)) * " triangles")
end

function is_active_triangle(m::Mesh, tri)
    return m.active_triangle[tri]
end

function is_active_edge(m::Mesh, edgeid)
    return m.active_edge[edgeid]
end

function degree(m::Mesh, vertex_idx)
    return m.d[vertex_idx]
end

function vertex(m::Mesh, tri_idx, ver_idx)
    return m.t[tri_idx, ver_idx]
end

function increment_degree!(m::Mesh, vertex_idx)
    m.d[vertex_idx] += 1
end

function increment_degree!(m::Mesh, tri_idx, ver_idx)
    increment_degree!(m, vertex(m, tri_idx, ver_idx))
end

function decrement_degree!(m::Mesh, vertex_idx)
    m.d[vertex_idx] -= 1
end

function decrement_degree!(m::Mesh, tri_idx, ver_idx)
    decrement_degree!(m, vertex(m, tri_idx, ver_idx))
end

function insert_vertex!(m::Mesh, coords, deg, on_boundary)
    m.p = [m.p; coords']
    push!(m.d, deg)
    push!(m.vertex_on_boundary, on_boundary)
    m.num_vertices += 1
end

function insert_triangle!(m::Mesh, conn, t2t, t2n, t2e)
    m.t = [m.t; conn']
    m.t2t = [m.t2t; t2t']
    m.t2n = [m.t2n; t2n']
    m.t2e = [m.t2e; t2e']
    push!(m.active_triangle, true)
    m.num_triangles += 1
end

function insert_edge!(m::Mesh, source, target, on_boundary)
    e = [min(source,target), max(source,target)]
    m.edges = [m.edges; e']
    push!(m.active_edge, true)
    push!(m.edge_on_boundary, on_boundary)
    m.num_edges += 1
end

function delete_triangle!(m::Mesh, tri_idx)
    m.active_triangle[tri_idx] = false
    m.num_triangles -= 1
end

function delete_edge!(m::Mesh, edge_idx)
    m.active_edge[edge_idx] = false
    m.num_edges -= 1
end

function refine(p, t, edges, t2e)
    np, dim = size(p)

    # find the midpoint of each edge
    pmid = (p[edges[:, 1], :] + p[edges[:, 2], :]) / 2
    t1 = t[:, 1]
    t2 = t[:, 2]
    t3 = t[:, 3]
    t23 = t2e[:, 1] .+ np
    t31 = t2e[:, 2] .+ np
    t12 = t2e[:, 3] .+ np

    t = [
        t1 t12 t31
        t12 t23 t31
        t2 t23 t12
        t3 t31 t23
    ]
    p = [p; pmid]

    return p, t
end

function refine(m::Mesh)
    active_t = m.t[m.active_triangle, :]
    active_e = m.edges[m.active_edge, :]
    active_t2e = m.t2e[m.active_triangle, :]
    p, t = refine(m.p, active_t, active_e, active_t2e)
    return Mesh(p, t)
end