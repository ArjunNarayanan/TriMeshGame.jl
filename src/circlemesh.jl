function template_circlemesh()
    # make coarsest mesh on unit circle with points at 60,120,180,...,360 degrees
    phi = 2pi * (1:6) / 6

    p = [0 0; cos.(phi) sin.(phi)]
    # coarsest mesh connectivity with 6 triangles
    t = [1 2 3; 1 3 4; 1 4 5; 1 5 6; 1 6 7; 1 7 2]

    return p, t
end

function correct_boundary_vertices!(p, boundary_nodes)
    p[boundary_nodes, :] =
        p[boundary_nodes, :] ./ sqrt.(sum(p[boundary_nodes, :] .^ 2, dims = 2))
end

function averagesmoothing!(p, edges, active_edges, bnd_nodes; numiter = 1)
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

function circlemesh(nref)
    p, t = template_circlemesh()
    edges, boundary_edges, t2e = all_edges(t)
    bnd_nodes = boundary_vertices(edges, boundary_edges)

    for ref = 1:nref
        p, t = refine(p, t, edges, t2e)
        edges, boundary_edges, t2e = all_edges(t)
        bnd_nodes = boundary_vertices(edges, boundary_edges)
        correct_boundary_vertices!(p, bnd_nodes)
        averagesmoothing!(p, edges, trues(size(edges,1)), bnd_nodes, numiter = 5)
    end

    return Mesh(p, t)
end