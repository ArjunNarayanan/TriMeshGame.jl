using PyPlot
using PyCall
@pyimport matplotlib.patches as patches

function plot_triangle!(ax, coords)
    p = patches.Polygon(coords, fill = false)
    ax.add_patch(p)
end

function plot_mesh!(ax, mesh)
    xlim = [Inf,-Inf]
    ylim = [Inf,-Inf]
    for t in mesh.triangles
        coords = transpose(cat([v.coordinates for v in t.vertices]...,dims=2))

        xlim[1] = min(xlim[1],minimum(coords[:,1]))
        xlim[2] = max(xlim[2],maximum(coords[:,1]))
        ylim[1] = min(ylim[1],minimum(coords[:,2]))
        ylim[2] = max(ylim[2],maximum(coords[:,2]))

        plot_triangle!(ax, coords)
    end

    ax.set_xlim(xlim...)
    ax.set_ylim(ylim...)
end

function plot_mesh(mesh)
    fig, ax = subplots()
    ax.set_aspect("equal")
    ax.axis("off")
    plot_mesh!(ax, mesh)
    fig.tight_layout()

    return fig
end