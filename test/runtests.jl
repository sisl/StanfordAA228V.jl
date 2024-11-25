using AA228V
using Random
using Test

const SEED = sum(Int.(collect("AA228V")))

# include(joinpath(@__DIR__, "..", "projects", "project0", "project0.jl"))
include(joinpath(@__DIR__, "..", "projects", "answer0", "answer0.jl"))

function test0(n_failures::Function; d=100, n=1000, seed=SEED)
    Random.seed!(seed)

    agent = NoAgent()
    env = SimpleGaussian()
    sensor = IdealSensor()
    sys = System(agent, env, sensor)
    ψ = LTLSpecification(@formula □(s->s > -2))

    return n_failures(sys, ψ; d, n)
end

# Runs your version of `num_failures` from `project0.jl`
@testset "Project 0" begin
    @test test0(num_failures; d=100, n=1000, seed=SEED) == 19
    @test test0(num_failures; d=100, n=5000, seed=SEED) == 110
end
