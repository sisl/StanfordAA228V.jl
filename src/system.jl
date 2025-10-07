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
    rollout(sys::System[, s₀]; d=1)

Generate rollout trajectory by applying `step(sys, s; d)` at each step.
Initial state `s₀` can be provided or is sampled from `Ps(sys.env)`.
You may want to set `d=get_depth(sys)`.

See also [`Ps`](@ref), [`step`](@ref), [`get_depth`](@ref).
"""
function rollout(sys::System, s₀; d=1)
    s = s₀
    τ = []
    for t in 1:d
        o, a, s′ = step(sys, s)
        push!(τ, (; s, o, a))
        s = s′
    end
    return τ
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

"""
    rollout(sys::System[, s₀], 𝐱::AbstractVector; d=length(𝐱))

Rollout `sys` using vector of noise samples `𝐱`.
Initial state `s₀` can be provided or is sampled from `Ps(sys.env)`.

# Examples
```jldoctest
julia> using StanfordAA228V, Distributions, LinearAlgebra
julia> Σₒ = Diagonal([deg2rad(1.0), deg2rad(1.0)])
julia> x = [(; xo = rand(MvNormal([0.1; 0.0], Σₒ)),  # biased mean
               xs = [0.0; 0.0],
               xa = 0)
            for _ in 1:20];
julia> struct SignAgent <: Agent end
julia> (::SignAgent)(s, a=missing) = -sign(s[1])  # define `agent(s, a)` when `agent isa Signagent`
julia> sys = System(SignAgent(),
                    InvertedPendulum(),
                    AdditiveNoiseSensor(MvNormal(Σₒ)))
julia> s0 = rand(Ps(sys.env))
julia> τ = rollout(sys, x);
julia> abs(last(τ).s[1]) > pi/4
True
```
"""
function rollout(sys::System, s₀, 𝐱::AbstractVector; d=length(𝐱))
    s = s₀
    τ = []
    for t in 1:d
        x = 𝐱[t]
        o, a, s′ = step(sys, s, x)
        push!(τ, (; s, o, a, x))
        s = s′
    end
    return τ
end
# The two-arg noise rollout conflicts with `rollout(sys, s₀)` so we can't provide it.
# rollout(sys::System, 𝐱::AbstractVector; d=length(𝐱)) = rollout(sys, rand(Ps(sys.env)), 𝐱; d)

"""
    rollout(sys::System[, s₀], p::TrajectoryDistribution; d=depth(p))

Rollout `sys` using noise and an initial state drawn according to the trajectory distribution.
One instantiation of a `TrajectoryDistribution` is the `NominalTrajectoryDistribution`
which results in equivalent rollouts to the 1-arg `rollout(sys)` function.

# Examples
```jldoctest
julia> import LinearAlgebra, Random
julia> Σₒ = Diagonal([deg2rad(1.0), deg2rad(1.0)])
julia> sys = System(ProportionalController(rand(2)),
                    InvertedPendulum(),
                    AdditiveNoiseSensor(MvNormal(Σₒ)))
julia> Random.seed!(1)
julia> τ1 = rollout(sys; d=5)
julia> Random.seed!(1)
julia> τ2 = rollout(sys, NominalTrajectoryDistribution(sys, 5))
julia> [s for (; s, o, a) in τ1] .≈ [s for (; s, o, a) in τ2]
true
```

See also [`NominalTrajectoryDistribution`](@ref).
"""
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
