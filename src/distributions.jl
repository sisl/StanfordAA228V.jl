@with_kw struct Deterministic <: ContinuousUnivariateDistribution
    val::Real = 0
end

function Distributions.rand(rng::AbstractRNG, d::Deterministic)
    rand(rng)
    return d.val
end
Distributions.logpdf(d::Deterministic, x::T) where T<:Real = zero(x)

# Bijectors.bijector(d::Deterministic) = identity

Ds(env::Environment, s, a) = Deterministic()
Da(agent::Agent, o) = Deterministic()
Do(sensor::Sensor, s) = Deterministic()

function DisturbanceDistribution(sys::System)
    return DisturbanceDistribution((o) -> Da(sys.agent, o),
                                   (s, a) -> Ds(sys.env, s, a),
                                   (s) -> Do(sys.sensor, s))
end
