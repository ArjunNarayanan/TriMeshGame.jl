function template_circlemesh()
    # make coarsest mesh on unit circle with points at 60,120,180,...,360 degrees
    phi = 2pi * (1:6) / 6

    p = [
        0 cos.(phi)'
        0 sin.(phi)'
    ]
    # coarsest mesh connectivity with 6 triangles
    t = [
        1 1 1 1 1 1
        2 3 4 5 6 7
        3 4 5 6 7 2
    ]

    return p, t
end

function refine(p, t, edges, t2e)
    dim, np = size(p)
    
    # find the midpoint of each edge
    pmid = (p[:, edges[1, :]] + p[:, edges[2, :]]) / 2
    t1 = t[1, :]
    t2 = t[2, :]
    t3 = t[3, :]
    t23 = t2e[1, :] .+ np
    t31 = t2e[2, :] .+ np
    t12 = t2e[3, :] .+ np

    t = [
        t1 t12 t31
        t12 t23 t31
        t2 t23 t12
        t3 t31 t23
    ]
    p = hcat(p, pmid)

    t = Array(transpose(t))

    return p, t
end

function correct_boundary_vertices!(p, boundary_nodes)
    p[:, boundary_nodes] =
        p[:, boundary_nodes] ./ sqrt.(sum(p[:, boundary_nodes] .^ 2, dims = 1))
end

function averagesmoothing!(p, edges, bnd_nodes; numiter = 1)
    for iter = 1:numiter
        dim, np = size(p)
        newp = zeros(2, np)
        ddeg = zeros(np)

        for i = 1:size(edges, 2)
            newp[:, edges[[1, 2], i]] += p[:, edges[[2, 1], i]]
            ddeg[edges[[1,2],i]] .+= 1
        end

        newp ./= transpose(ddeg)
        newp[:, bnd_nodes] = p[:, bnd_nodes]
        p .= newp
    end
end

function circlemesh(nref)
    p, t = template_circlemesh()
    edges, boundary_edges, t2e = all_edges(t)
    bnd_nodes = boundary_nodes(edges, boundary_edges)

    for ref = 1:nref
        p, t = refine(p, t, edges, t2e)
        edges, boundary_edges, t2e = all_edges(t)
        bnd_nodes = boundary_nodes(edges, boundary_edges)
        correct_boundary_vertices!(p, bnd_nodes)
        averagesmoothing!(p, edges, bnd_nodes, numiter = 5)
    end

    return p, t
end