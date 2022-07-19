# using TriMeshGame
using Test
using SafeTestsets

@safetestset "Test Mesh" begin
    include("test_mesh.jl")
end

@safetestset "Test Flip" begin
    include("test_flip.jl")
end

@safetestset "Test Split" begin
    include("test_split.jl")
end