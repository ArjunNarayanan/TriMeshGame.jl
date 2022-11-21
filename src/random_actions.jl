function random_actions!(mesh, num_actions)
    counter = 0

    while counter < num_actions
        tri = rand(findall(mesh.active_triangle))

        edge = rand(1:3)
        type = rand(1:3)
        flag = false

        if type == 1 # flip edge
            flag = edgeflip!(mesh, tri, edge)
            println("Flipping $tri, $edge succeeded $flag")
        elseif type == 2 && has_neighbor(mesh, tri, edge)
            println("Splitting $tri, $edge succeeded $flag")
            flag = split_interior_edge!(mesh, tri, edge)
        else # collapse edge
            flag = collapse!(mesh, tri, edge)
            println("Collapsing $tri, #edge succeeded $flag")
        end

        if flag
            counter += 1
        end

    end
end

function random_flips!(mesh, nflips)
    nt = total_num_triangles(mesh)
    counter = 0
    while counter < nflips
        tri = rand(1:nt)
        edge = rand(1:3)
        success = edgeflip!(mesh, tri, edge)
        if success
            counter += 1
        end
    end
end