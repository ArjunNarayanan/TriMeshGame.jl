function random_actions!(mesh, num_actions)
    counter = 0

    while counter < num_actions
        nt = total_num_triangles(mesh)

        tri = rand(1:nt)

        if is_active_triangle(mesh, tri)
            edge = rand(1:3)
            split = rand(Bool)
            if split
                if has_neighbor(mesh, tri, edge)
                    split_interior_edge!(mesh, tri, edge)
                    counter += 1
                end
            else
                flag = edgeflip!(mesh, tri, edge)
                if flag
                    counter += 1
                end
            end
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