"""
   Deterministic <: ContinuousUnivariateDistribution 

Deterministic "distribution", always returns its own value.

# Examples
```jldoctest
julia> using StanfordAA228V

julia> rand(Deterministic())
0

julia> rand(Deterministic(5))
5
```

See also [`Normal`](@extref Distributions.Normal), [`MvNormal`](@extref Distributions.MvNormal).
"""
@with_kw struct Deterministic <: ContinuousUnivariateDistribution
    val::Real = 0
end

function Distributions.rand(rng::AbstractRNG, d::Deterministic)
    rand(rng)
    return d.val
end
Distributions.logpdf(d::Deterministic, x::T) where T<:Real = zero(x)
Distributions.mean(d::Deterministic) = d.val

# Bijectors.bijector(d::Deterministic) = identity

"""
    Ds(env::Environment, s, a)

Return the nominal noise distribution for the dynamics.
For example
```jldoctest
julia> using StanfordAA228V, Distributions

julia> Ds(SimpleGaussian(), [0], [0])  # SimpleGaussian has no dynamics noise
Deterministic
  val: Int64 0

julia> rand(Ds(SimpleGaussian(), [0], [0]))  # we can still sample from this
0

julia> env = ContinuumWorldSurrogate(model=nothing);  # other environments have dynamics noise

julia> rand(Ds(env, zeros(2), 0));
```

More details for each system are provided in the project files themselves.

See also [`DisturbanceDistribution`](@ref).
"""
Ds(env::Environment, s, a) = Deterministic()

"""
    Da(agent::Agent, o)

Return the nominal noise distribution for the action.
See also [`Ds`](@ref), [`DisturbanceDistribution`](@ref).
"""
Da(agent::Agent, o) = Deterministic()

"""
    Do(sensor::Sensor, s)

Return the nominal noise distribution for the observation.
See also [`Ds`](@ref), [`DisturbanceDistribution`](@ref).
"""
Do(sensor::Sensor, s) = Deterministic()

function DisturbanceDistribution(sys::System)
    return DisturbanceDistribution((o) -> Da(sys.agent, o),
                                   (s, a) -> Ds(sys.env, s, a),
                                   (s) -> Do(sys.sensor, s))
end
