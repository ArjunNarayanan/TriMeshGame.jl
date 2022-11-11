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

@testset "Test Game Env" begin
    include("test_game_env.jl")
end