"""
    mkt2t(t)

returns `t2t,t2n` where
    `t2t[triangle_index, half_edge_index]` provides the triangle-to-triangle connectivity
    `t2n[triangle_index, half_edge_index]` provides the local half-edge index in the neighboring triangle
"""
function mkt2t(t)
    map = [2 3 1
        3 1 2]
    ne, nt = size(map, 2), size(t, 2)

    t2t = zeros(Int, ne, nt)
    t2n = zeros(Int, ne, nt)
    dd = Dict{Tuple{Int,Int},Tuple{Int,Int}}()
    sizehint!(dd, nt * ne)
    for it = 1:nt
        for ie = 1:ne
            e1 = t[map[1, ie], it]
            e2 = t[map[2, ie], it]
            e = (min(e1, e2), max(e1, e2))
            if haskey(dd, e)
                nb = pop!(dd, e)
                t2t[ie, it] = nb[1]
                t2n[ie, it] = nb[2]
                t2t[nb[2], nb[1]] = it
                t2n[nb[2], nb[1]] = ie
            else
                dd[e] = (it, ie)
            end
        end
    end
    t2t, t2n
end


function all_edges(connectivity)
    etag =
        [connectivity[[1, 2], :] connectivity[[2, 3], :] connectivity[[3, 1], :]]
    etag = sort(etag, dims=1)
    etag = sortslices(etag, dims=2)

    dup = vec(all(etag[:, 2:end] - etag[:, 1:end-1] .== 0, dims=1))
    keep = .![false; dup]
    edges = etag[:, keep]

    dup = [dup; false]
    dup = dup[keep]
    bndix = findall(.!dup)

    return edges, bndix
end


function boundary_vertices(edges, boundary_edges)
    return unique(vec(edges[:, boundary_edges]))
end

function vertex_degrees(edges, num_vertices)
    d = zeros(Int, num_vertices)
    for (i, col) in enumerate(eachcol(edges))
        d[edges[[1, 2], i]] .+= 1
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
    vertices::Matrix{Float64}
    connectivity::Matrix{Int64}
    t2t::Matrix{Int64}
    t2n::Matrix{Int64}

    degrees::Vector{Int64}
    vertex_on_boundary::Vector{Bool}

    active_triangle::Vector{Bool}
    active_vertex::Vector{Bool}

    num_vertices::Int
    num_triangles::Int

    function Mesh(vertices, connectivity)

        num_triangles = size(connectivity, 2)
        num_vertices = size(vertices, 2)

        @assert size(vertices, 1) == 2
        @assert size(connectivity, 1) == 3

        t2t, t2n = mkt2t(connectivity)

        @assert size(t2t, 1) == 3
        @assert size(t2n, 1) == 3

        edges, bndix = all_edges(connectivity)
        
        boundary_vertex = boundary_vertices(edges, bndix)
        vertex_on_boundary = falses(num_vertices)
        vertex_on_boundary[boundary_vertex] .= true

        degrees = vertex_degrees(edges, num_vertices)

        triangle_buffer = 2 * num_triangles
        vertex_buffer = 2 * num_vertices

        _vertices = zeros(2, vertex_buffer)
        _vertices[:, 1:num_vertices] .= vertices

        _connectivity = zeros(3, triangle_buffer)
        _connectivity[:, 1:num_triangles] .= connectivity

        _t2t = zeros(3, triangle_buffer)
        _t2t[:, 1:num_triangles] .= t2t

        _t2n = zeros(3, triangle_buffer)
        _t2n[:, 1:num_triangles] .= t2n

        _degrees = zeros(Int, vertex_buffer)
        _degrees[1:num_vertices] .= degrees

        active_triangles = falses(triangle_buffer)
        active_triangles[1:num_triangles] .= true

        active_vertices = falses(vertex_buffer)
        active_vertices[1:num_vertices] .= true
        _vertex_on_boundary = falses(vertex_buffer)
        _vertex_on_boundary[1:num_vertices] .= vertex_on_boundary

        return new(
            _vertices,
            _connectivity,
            _t2t,
            _t2n,
            _degrees,
            _vertex_on_boundary,
            active_triangles,
            active_vertices,
            num_vertices,
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
    return m.t2t[tri, ver] != 0
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

function active_degrees(mesh)
    return mesh.degrees[mesh.active_vertex]
end

function active_vertices(mesh)
    return mesh.vertices[:, mesh.active_vertex]
end

function active_connectivity(mesh)
    return mesh.connectivity[:, mesh.active_triangle]
end

function active_t2t(mesh)
    return mesh.t2t[:, mesh.active_triangle]
end

function active_t2n(mesh)
    return mesh.t2n[:, mesh.active_triangle]
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
    e = [min(source, target), max(source, target)]
    m.edges = [m.edges; e']
    push!(m.active_edge, true)
    push!(m.edge_on_boundary, on_boundary)
    m.num_edges += 1
end

function delete_triangle!(m::Mesh, tri_idx)
    m.active_triangle[tri_idx] = false
    m.t[tri_idx, :] .= 0
    m.t2t[tri_idx, :] .= 0
    m.t2n[tri_idx, :] .= 0
    m.num_triangles -= 1
end

function delete_edge!(m::Mesh, edge_idx)
    m.active_edge[edge_idx] = false
    m.num_edges -= 1
end