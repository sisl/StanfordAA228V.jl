## Agent
struct NoAgent <: Agent end
(c::NoAgent)(s, a=missing) = nothing
Distributions.pdf(c::NoAgent, s, x) = 1.0

## Environment
"""
    SimpleGaussian <: Environment

A simple environment which initializes to a random Gaussian initial state and
has no further dynamics.
"""
struct SimpleGaussian <: Environment end
(env::SimpleGaussian)(s, a, xs=missing) = s

Ps(env::SimpleGaussian) = Normal()

## Sensor
struct IdealSensor <: Sensor end

(sensor::IdealSensor)(s) = s
(sensor::IdealSensor)(s, x) = sensor(s)

Distributions.pdf(sensor::IdealSensor, s, xₛ) = 1.0

const Project1SmallSystem::Type = System{NoAgent, SimpleGaussian, IdealSensor}
const Project2SmallSystem::Type = Project1SmallSystem

"""
    get_depth(sys::Project1SmallSystem)

The [`SimpleGaussian`](@ref) environment runs for a single step only.
"""
get_depth(sys::Project1SmallSystem) = 1

# we have to define this for compatibility as we usually require s0 to be a vector except for this system
function rollout(sys::System{AT, SimpleGaussian}, s₀::Number; d=1) where {AT}
    s = s₀
    τ = []
    D = DisturbanceDistribution(sys)
    for _ in 1:d
        o, a, s′, x = step(sys, s, D)
        push!(τ, (; s, o, a, x))
        s = s′
    end
    return identity.(τ)  # `identity` converts `Vector{Any}` to concrete vector
end
