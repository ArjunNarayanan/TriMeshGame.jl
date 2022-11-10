function template_circlemesh()
    # make coarsest mesh on unit circle with points at 60,120,180,...,360 degrees
    phi = 2pi * (1:6) / 6

    p = [0 0; cos.(phi) sin.(phi)]
    # p = Array(p')
    # coarsest mesh connectivity with 6 triangles
    t = [1 2 3; 1 3 4; 1 4 5; 1 5 6; 1 6 7; 1 7 2]
    # t = Array(t')

    return p, t
end

function correct_boundary_vertices!(p, boundary_nodes)
    p[boundary_nodes, :] =
        p[boundary_nodes, :] ./ sqrt.(sum(p[boundary_nodes, :] .^ 2, dims = 2))
end

function averagesmoothing!(p, edges, active_edges, bnd_nodes, numiter)
    for iter = 1:numiter
        np, dim = size(p)
        newp = zeros(np, 2)
        ddeg = zeros(np)

        for i = 1:size(edges, 1)
            if active_edges[i]
                newp[edges[i, [1, 2]], :] += p[edges[i, [2, 1]], :]
                ddeg[edges[i, [1, 2]]] .+= 1
            end
        end

        newp ./= ddeg
        newp[bnd_nodes, :] = p[bnd_nodes, :]
        p .= newp
    end
end

function averagesmoothing!(mesh, numiter)
    bnd_ver = findall(mesh.vertex_on_boundary)
    averagesmoothing!(mesh.p, mesh.edges, mesh.active_edge, bnd_ver, numiter)
end

function all_edges_with_t2e(t)
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

function circlemesh(nref)
    p, t = template_circlemesh()
    edges, boundary_edges, t2e = all_edges_with_t2e(t)
    bnd_nodes = boundary_vertices(edges', boundary_edges)

    for ref = 1:nref
        p, t = refine(p, t, edges, t2e)
        edges, boundary_edges, t2e = all_edges_with_t2e(t)
        bnd_nodes = boundary_vertices(edges', boundary_edges)
        correct_boundary_vertices!(p, bnd_nodes)
        averagesmoothing!(p, edges, trues(size(edges,1)), bnd_nodes, 3)
    end

    p = Array(p')
    t = Array(t')
    return Mesh(p, t)
end