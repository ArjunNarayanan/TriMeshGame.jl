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

    new_vertex_pointer
    new_triangle_pointer

    growth_factor

    function Mesh(vertices, connectivity; growth_factor = 2)
        @assert growth_factor > 1

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

        new_vertex_pointer = num_vertices+1
        new_triangle_pointer = num_triangles+1

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
            new_vertex_pointer,
            new_triangle_pointer,
            growth_factor
        )
    end
end

function num_vertices(m::Mesh)
    return m.num_vertices
end


function num_triangles(m::Mesh)
    return m.num_triangles
end

function vertex_buffer(m::Mesh)
    return size(m.vertices, 2)
end

function triangle_buffer(mesh)
    return size(mesh.connectivity, 2)
end

function growth_factor(mesh)
    return mesh.growth_factor
end

function has_neighbor(m::Mesh, tri, ver)
    @assert is_active_triangle(m, tri)
    opp_tri = m.t2t[ver, tri]
    if opp_tri > 0
        @assert is_active_triangle(m, opp_tri)
        return true
    else
        return false
    end
end

function Base.show(io::IO, m::Mesh)
    println(io, "Mesh:")
    println(io, "  " * string(num_vertices(m)) * " vertices")
    println(io, "  " * string(num_triangles(m)) * " triangles")
end

function is_active_triangle(m::Mesh, tri)
    return m.active_triangle[tri]
end

function is_active_triangle_or_boundary(mesh, tri)
    return tri == 0 || mesh.active_triangle[tri]
end

function degree(mesh::Mesh, vertex_idx)
    @assert is_active_vertex(mesh, vertex_idx)
    return mesh.degrees[vertex_idx]
end

function set_degree!(mesh, vertex_idx, deg)
    @assert is_active_vertex(mesh, vertex_idx)
    mesh.degrees[vertex_idx] = deg
end

function vertex(mesh::Mesh, local_vertex_idx, tri_idx)
    @assert is_active_triangle(mesh, tri_idx)
    return mesh.connectivity[local_vertex_idx, tri_idx]
end

function vertex_coordinates(mesh, vertex_idx)
    @assert is_active_vertex(mesh, vertex_idx)
    return mesh.vertices[:, vertex_idx]
end

function set_vertex_coordinates!(mesh, vertex_idx, coords)
    @assert is_active_vertex(mesh, vertex_idx)
    mesh.vertices[:, vertex_idx] .= coords
end

function vertex_on_boundary(mesh, vertex_idx)
    @assert is_active_vertex(mesh, vertex_idx)
    return mesh.vertex_on_boundary[vertex_idx]
end

function set_vertex_on_boundary!(mesh, vertex_idx, on_boundary)
    @assert is_active_vertex(mesh, vertex_idx)
    mesh.vertex_on_boundary[vertex_idx] = on_boundary
end


function neighbor_triangle(mesh, local_vertex, triangle)
    @assert is_active_triangle(mesh, triangle)
    return mesh.t2t[local_vertex, triangle]
end

function neighbor_twin(mesh, local_vertex, triangle)
    @assert is_active_triangle(mesh, triangle)
    return mesh.t2n[local_vertex, triangle]
end

function is_active_vertex(mesh, vertex)
    return mesh.active_vertex[vertex]
end

function active_degrees(mesh)
    return mesh.degrees[mesh.active_vertex]
end

function active_vertex_degrees(mesh)
    return active_degrees(mesh)
end

function active_vertex_on_boundary(mesh)
    return mesh.vertex_on_boundary[mesh.active_vertex]
end

function increment_degree!(mesh::Mesh, vertex_idx)
    @assert is_active_vertex(mesh, vertex_idx)
    mesh.degrees[vertex_idx] += 1
end

function increment_degree!(mesh::Mesh, local_vertex_idx, tri_idx)
    @assert is_active_triangle(mesh, tri_idx)
    increment_degree!(mesh, vertex(mesh, local_vertex_idx, tri_idx))
end

function decrement_degree!(mesh::Mesh, vertex_idx)
    @assert is_active_vertex(mesh, vertex_idx)
    mesh.degrees[vertex_idx] -= 1
end

function replace_index_in_connectivity(mesh, old_index, new_index)
    conn = mesh.connectivity
    conn[conn .== old_index] .= new_index
end

function decrement_degree!(mesh::Mesh, local_vertex_idx, tri_idx)
    @assert is_active_triangle(mesh, tri_idx)
    decrement_degree!(mesh, vertex(mesh, local_vertex_idx, tri_idx))
end

function active_vertex_coordinates(mesh)
    return mesh.vertices[:, mesh.active_vertex]
end

function active_triangle_connectivity(mesh)
    return mesh.connectivity[:, mesh.active_triangle]
end

function active_t2t(mesh)
    return mesh.t2t[:, mesh.active_triangle]
end

function active_triangle_t2t(mesh)
    return active_t2t(mesh)
end

function set_t2t!(mesh, tri, new_t2t)
    @assert is_active_triangle(mesh, tri)
    @assert all((is_active_triangle_or_boundary(mesh, t) for t in new_t2t))
    mesh.t2t[:, tri] .= new_t2t
end

function set_t2t!(mesh, ver, tri, t2t)
    @assert is_active_triangle(mesh, tri)
    @assert is_active_triangle_or_boundary(mesh, t2t)

    mesh.t2t[ver, tri] = t2t
end

function set_neighbor_triangle!(mesh, vertex_idx, triangle_idx, nbr_triangle_idx)
    @assert is_active_triangle(mesh, triangle_idx)
    @assert is_active_triangle_or_boundary(mesh, nbr_triangle_idx)
    mesh.t2t[vertex_idx, triangle_idx] = nbr_triangle_idx
end

function set_neighbor_triangle_if_not_boundary!(mesh, local_vertex, triangle, nbr_triangle)
    if local_vertex > 0 && triangle > 0
        set_neighbor_triangle!(mesh, local_vertex, triangle, nbr_triangle)
    end
end

function set_neighbor_twin!(mesh, vertex_idx, triangle_idx, nbr_twin)
    @assert is_active_triangle(mesh, triangle_idx)
    @assert is_valid_local_vertex_index_or_boundary(nbr_twin)
    mesh.t2n[vertex_idx, triangle_idx] = nbr_twin
end

function set_neighbor_twin_if_not_boundary!(mesh, local_vertex, triangle, nbr_twin)
    if local_vertex > 0 && triangle > 0
        set_neighbor_twin!(mesh, local_vertex, triangle, nbr_twin)
    end
end

function active_t2n(mesh)
    return mesh.t2n[:, mesh.active_triangle]
end

function active_triangle_t2n(mesh)
    return active_t2n(mesh)
end

function is_valid_local_vertex_index_or_boundary(index)
    return any((index == i for i in (0,1,2,3)))
end

function set_t2n!(mesh, ver, tri, t2n)
    @assert is_active_triangle(mesh, tri)
    @assert is_valid_local_vertex_index_or_boundary(t2n)
    mesh.t2n[ver, tri] = t2n
end

function set_t2n!(mesh, tri, new_t2n)
    @assert is_active_triangle(mesh, tri)
    @assert all((is_valid_local_vertex_index_or_boundary(i) for i in new_t2n))
    mesh.t2n[:, tri] .= new_t2n
end

function expand_vertices!(mesh)
    vb = vertex_buffer(mesh)
    new_vert_buff_size = growth_factor(mesh) * vb
    num_new_entries = new_vert_buff_size - vb

    mesh.vertices = zero_pad(mesh.vertices, num_new_entries)
    mesh.degrees = zero_pad(mesh.degrees, num_new_entries)
    mesh.vertex_on_boundary = zero_pad(mesh.vertex_on_boundary, num_new_entries)
    mesh.active_vertex = zero_pad(mesh.active_vertex, num_new_entries)
end

function insert_vertex!(mesh::Mesh, coords, deg, on_boundary)
    new_idx = mesh.new_vertex_pointer

    if new_idx > vertex_buffer(mesh)
        expand_vertices!(mesh)
    end
    @assert new_idx <= vertex_buffer(mesh)

    mesh.vertices[:, new_idx] .= coords
    mesh.degrees[new_idx] = deg
    mesh.vertex_on_boundary[new_idx] = on_boundary
    mesh.active_vertex[new_idx] = true

    mesh.num_vertices += 1
    mesh.new_vertex_pointer += 1
    return new_idx
end

function expand_triangles!(mesh)
    tri_buff = triangle_buffer(mesh)
    new_tri_buff_size = growth_factor(mesh) * tri_buff
    num_new_entries = new_tri_buff_size - tri_buff

    mesh.connectivity = zero_pad(mesh.connectivity, num_new_entries)
    mesh.t2t = zero_pad(mesh.t2t, num_new_entries)
    mesh.t2n = zero_pad(mesh.t2n, num_new_entries)
    mesh.active_triangle = zero_pad(mesh.active_triangle, num_new_entries)
end

function insert_triangle!(mesh::Mesh, conn, t2t = (0,0,0), t2n = (0,0,0))
    new_idx = mesh.new_triangle_pointer
    if new_idx > triangle_buffer(mesh)
        expand_triangles!(mesh)
    end
    @assert new_idx <= triangle_buffer(mesh)

    mesh.connectivity[:, new_idx] .= conn
    mesh.t2t[:, new_idx] .= t2t
    mesh.t2n[:, new_idx] .= t2n
    mesh.active_triangle[new_idx] = true
    
    mesh.num_triangles += 1
    mesh.new_triangle_pointer += 1

    return new_idx
end

function delete_triangle!(mesh::Mesh, tri_idx)
    @assert is_active_triangle(mesh, tri_idx)

    mesh.active_triangle[tri_idx] = false
    mesh.connectivity[:, tri_idx] .= 0
    mesh.t2t[:, tri_idx] .= 0
    mesh.t2n[:, tri_idx] .= 0
    mesh.num_triangles -= 1
end

function delete_vertex!(mesh, vertex_idx)
    @assert is_active_vertex(mesh, vertex_idx)
    mesh.active_vertex[vertex_idx] = false
    mesh.degrees[vertex_idx] = 0
    mesh.num_vertices -= 1
end

function reindex_vertices!(mesh)
    vertex_buffer_size = vertex_buffer(mesh)
    new_vertex_indices = zeros(Int, vertex_buffer_size)
    num_verts = num_vertices(mesh)
    active_verts = mesh.active_vertex
    new_vertex_indices[active_verts] .= 1:num_verts
    
    num_extra_vertices = vertex_buffer_size - num_verts
    mesh.vertices = zero_pad(active_vertex_coordinates(mesh), num_extra_vertices)

    active_conn = active_triangle_connectivity(mesh)
    new_conn = [new_vertex_indices[v] for v in active_conn]
    mesh.connectivity[:, mesh.active_triangle] .= new_conn

    mesh.degrees = zero_pad(mesh.degrees[active_verts], num_extra_vertices)    
    mesh.vertex_on_boundary = zero_pad(mesh.vertex_on_boundary[active_verts], num_extra_vertices)
    mesh.active_vertex = zero_pad(trues(num_verts), num_extra_vertices)
    mesh.new_vertex_pointer = num_verts + 1

    return new_vertex_indices
end

function reindex_triangles!(mesh)
    triangle_buffer_size = triangle_buffer(mesh)
    new_triangle_indices = zeros(Int, triangle_buffer_size)
    num_tris = num_triangles(mesh)
    new_triangle_indices[mesh.active_triangle] .= 1:num_tris
    num_extra_tris = triangle_buffer_size - num_tris

    new_t2t = active_t2t(mesh)
    new_t2t = [t > 0 ? new_triangle_indices[t] : 0 for t in new_t2t]
    mesh.t2t = zero_pad(new_t2t, num_extra_tris)
    
    mesh.connectivity = zero_pad(active_triangle_connectivity(mesh), num_extra_tris)
    mesh.t2n = zero_pad(active_t2n(mesh), num_extra_tris)
    mesh.active_triangle = zero_pad(trues(num_tris), num_extra_tris)
    mesh.new_triangle_pointer = num_tris + 1

    return new_triangle_indices
end

function reindex!(mesh::Mesh)
    reindex_vertices!(mesh)
    reindex_triangles!(mesh)
end

function averagesmoothing!(mesh::Mesh)
    boundary_nodes = findall(mesh.vertex_on_boundary)
    mesh.vertices = averagesmoothing(mesh.vertices, mesh.connectivity, mesh.t2t, mesh.active_triangle, boundary_nodes)
end