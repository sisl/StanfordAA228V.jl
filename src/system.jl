abstract type Agent end
abstract type Environment end
abstract type Sensor end

struct System{A<:Agent, E<:Environment, S<:Sensor}
    agent::A
    env::E
    sensor::S
end

@counted function Base.step(sys::System, s)
    o = sys.sensor(s)
    a = sys.agent(o)
    s′ = sys.env(s, a)
    return (; o, a, s′)
end

"""
    rollout(sys::System; d=1)
    rollout(sys::System, s₀::VR; d=1) where VR <: Vector{<:Real}
    rollout(sys::System, pτ::TrajectoryDistribution; d=1)
    rollout(sys::System, s₀, pτ::TrajectoryDistribution; d=1)
    rollout(sys::System, 𝐱::VX; d=length(𝐱)) where VX <: Vector{<:NamedTuple}
    rollout(sys::System, s₀, 𝐱; d=length(𝐱))

Generate rollout trajectory of system `sys` by applying [`step(sys, s)`](@ref)
or [`step(sys, s, x)`](@ref) at each step.
Returns a vector of steps where each step is a `NamedTuple` `(o, a, s, x)`
or `(o, a, s, x)`.

Both the initial state and noise trajectory can be optionally provided.

# Initial State
The initial state can be provided via `s₀` and is otherwise sampled from [`Ps(sys.env)`](@ref Ps).

## Examples
```jldoctest rollout
julia> using StanfordAA228V

julia> sys = System(ProportionalController([0, 0]),
                    InvertedPendulum(),
                    IdealSensor());

julia> d = 5;

julia> rollout(sys);

julia> rollout(sys; d=d);

julia> s₀ = rand(2);

julia> rollout(sys, s₀; d=d);
```

# Noise Trajectory
The noise trajectory `τₓ` for observation noise `xo`, state noise `xs`, and
action noise `xa` is rolled out as follows:
- if no noise input is provided, [`NominalTrajectoryDistribution(sys, d=d)`](@ref NominalTrajectoryDistribution)
  is used to sample the noise at each step
- if a [`TrajectoryDistribution`](@ref) is provided this is used instead to sample the noise at each step
- if a vector of noise samples `τₓ = [(xo, xa, xs) for _ in 1:d]` is provided it is used as the noise at each step

## Examples
```jldoctest rollout
julia> # load sys as above

julia> import Random: seed!

julia> seed!(1); τ1 = rollout(sys; d=5);

julia> seed!(1); τ2 = rollout(sys, NominalTrajectoryDistribution(sys, 5));  # or another `FuzzingDistribution`

julia> [s for (; s, o, a) in τ1] ≈ [s for (; s, o, a) in τ2]
true

julia> τₓ = [(xo = -0.1 .+ randn(2), xa=nothing, xs=nothing)
             for _ in 1:5];

julia> rollout(sys, τₓ);

julia> rollout(sys, s₀, τₓ);
```
See [`TrajectoryDistribution`](@ref) for an example to set up your own `FuzzingDistribution` example.
See also [`NominalTrajectoryDistribution`](@ref), [`step`](@ref).

# A Note on Function Disambiguition
There is an interesting detail here how Julia diambiguates how to execute
- `rollout(sys, s₀)` versus
- `rollout(sys, τₓ)`.
In both cases the two-argument dispatch of `rollout` is called, but the
actual implementation is different depending on whether the second argument is
the initial state or a noise trajectory.

The solution is that Julia's dispatch mechanism checks the type of the second argument.
If `s₀ isa Vector{<:Real}`, i.e., a vector of e.g. `Float64`, then a different
function is called than when `τₓ isa Vector{<:NamedTuple}`.
If you want to learn more about this, check [Wikipedia: Multiple Dispatch](https://en.wikipedia.org/wiki/Multiple_dispatch)
and [Julia: Methods](https://docs.julialang.org/en/v1/manual/methods/).
"""
function rollout end

function rollout(sys::System, s₀::AbstractVector{<:Real}; d=1)
    s = s₀
    τ = []
    D = DisturbanceDistribution(sys)
    for _ in 1:d
        o, a, s′ = step(sys, s, D)
        push!(τ, (; s, o, a))
        s = s′
    end
    return identity.(τ)  # `identity` converts `Vector{Any}` to concrete vector
end
rollout(sys::System; d=1) = rollout(sys, rand(Ps(sys.env)); d)

struct Disturbance
    xa # agent disturbance
    xs # environment disturbance
    xo # sensor disturbance
end

struct DisturbanceDistribution
    Da # agent disturbance distribution
    Ds # environment disturbance distribution
    Do # sensor disturbance distribution
end

@counted function Base.step(sys::System, s, D::DisturbanceDistribution)
    xo = rand(D.Do(s))
    o = sys.sensor(s, xo)
    xa = rand(D.Da(o))
    a = sys.agent(o, xa)
    xs = rand(D.Ds(s, a))
    s′ = sys.env(s, a, xs)
    x = Disturbance(xa, xs, xo)
    return (; o, a, s′, x)
end

function Distributions.fit(d::DisturbanceDistribution, samples, w)
    𝐱_agent = [s.x.x_agent for s in samples]
    𝐱_env = [s.x.x_env for s in samples]
    𝐱_sensor = [s.x.x_sensor for s in samples]
    px_agent = fit(d.px_agent, 𝐱_agent, w)
    px_env = fit(d.px_env, 𝐱_env, w)
    px_sensor = fit(d.px_sensor, 𝐱_sensor, w)
    return DisturbanceDistribution(px_agent, px_env, px_sensor)
end

Distributions.fit(𝐝::Vector, samples, w) = [fit(d, [s[t] for s in samples], w) for (t, d) in enumerate(𝐝)]

Distributions.fit(d::Sampleable, samples, w::Missing) = fit(typeof(d), samples)
Distributions.fit(d::Sampleable, samples, w) = fit_mle(typeof(d), samples, w)

abstract type TrajectoryDistribution end
function initial_state_distribution(p::TrajectoryDistribution) end
function disturbance_distribution(p::TrajectoryDistribution, t) end
function depth(p::TrajectoryDistribution) end

(p::TrajectoryDistribution)(τ) = pdf(p, τ)

struct NominalTrajectoryDistribution <: TrajectoryDistribution
    Ps # initial state distribution
    D  # disturbance distribution
    d  # depth
end

function NominalTrajectoryDistribution(sys::System, d=1)
    D = DisturbanceDistribution((o) -> Da(sys.agent, o),
                                (s, a) -> Ds(sys.env, s, a),
                                (s) -> Do(sys.sensor, s))
    return NominalTrajectoryDistribution(Ps(sys.env), D, d)
end

initial_state_distribution(p::NominalTrajectoryDistribution) = p.Ps
disturbance_distribution(p::NominalTrajectoryDistribution, t) = p.D
depth(p::NominalTrajectoryDistribution) = p.d

function Distributions.logpdf(D::DisturbanceDistribution, s, o, a, x)
    logp_xa = logpdf(D.Da(o), x.xa)
    logp_xs = logpdf(D.Ds(s, a), x.xs)
    logp_xo = logpdf(D.Do(s), x.xo)
    return logp_xa + logp_xs + logp_xo
end

function Distributions.logpdf(p::TrajectoryDistribution, τ)
    logprob = logpdf(initial_state_distribution(p), τ[1].s)
    for (t, step) in enumerate(τ)
        s, o, a, x = step
        logprob += logpdf(disturbance_distribution(p, t), s, o, a, x)
    end
    return logprob
end

Distributions.pdf(p::TrajectoryDistribution, τ) = exp(logpdf(p, τ))

@counted function Base.step(sys::System, s, x)
    o = sys.sensor(s, x.xo)
    a = sys.agent(o, x.xa)
    s′ = sys.env(s, a, x.xs)
    return (; o, a, s′)
end

function rollout(sys::System, 𝐱::AbstractVector{<:NamedTuple}; d=length(𝐱))
    rollout(sys, rand(Ps(sys.env)), 𝐱; d)
end


function rollout(sys::System, s₀, 𝐱; d=length(𝐱))
    s = s₀
    τ = []
    for t in 1:d
        x = 𝐱[t]
        o, a, s′ = step(sys, s, x)
        push!(τ, (; s, o, a, x))
        s = s′
    end
    return identity.(τ)  # `identity` converts `Vector{Any}` to concrete vector
end

function rollout(sys::System, s, p::TrajectoryDistribution; d=depth(p))
    τ = []
    for t = 1:d
        o, a, s′, x = step(sys, s, disturbance_distribution(p, t))
        push!(τ, (; s, o, a, x))
        s = s′
    end
    return τ
end
rollout(sys::System, p::TrajectoryDistribution; d=depth(p)) =
    rollout(sys, rand(initial_state_distribution(p)), p; d)

function mean_step(sys::System, s, D::DisturbanceDistribution)
    xo = mean(D.Do(s))
    o = sys.sensor(s, xo)
    xa = mean(D.Da(o))
    a = sys.agent(o, xa)
    xs = mean(D.Ds(s, a))
    s′ = sys.env(s, a, xs)
    x = Disturbance(xa, xs, xo)
    return (; o, a, s′, x)
end

function mean_rollout(sys::System, p::TrajectoryDistribution; d=depth(p))
    s = mean(initial_state_distribution(p))
    τ = []
    for t = 1:d
        o, a, s′, x = mean_step(sys, s, disturbance_distribution(p, t))
        push!(τ, (; s, o, a, x))
        s = s′
    end
    return τ
end
