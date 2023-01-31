# using TriMeshGame
using Test

@testset "Test Mesh" begin
    include("test_mesh.jl")
end

@testset "Test Flip" begin
    include("test_flip.jl")
end

@testset "Test Split" begin
    include("test_split.jl")
end

@testset "Test Collapse" begin
    include("test_collapse.jl")
end

@testset "Test distance to boundary" begin
    include("test_distance_to_boundary.jl")
end

@testset "Test Game Env" begin
    include("test_game_env.jl")
end