abstract type Agent end
abstract type Environment end
abstract type Sensor end

"""
    Ps(env::Environment)

`Ps` denotes the nominal probability distribution over the initial state of the environment.
It is overloaded for each concrete environment, e.g., 
```julia
Ps(env::SimpleGaussian) = Normal()
```

In other words
```jldoctest
julia> using StanfordAA228V

julia> sys = System(ProportionalController([0, 0]), InvertedPendulum(), IdealSensor());

julia> initial_state_distribution(NominalTrajectoryDistribution(sys)) == Ps(sys.env)
true
```

See also [`initial_state_distribution`](@ref), [`NominalTrajectoryDistribution`](@ref).
"""
function Ps end


"""
    System{A<:Agent, E<:Environment, S<:Sensor}

`struct` defining a system. 

# Fields
- `agent`
- `env`
- `sensor`
"""
struct System{A<:Agent, E<:Environment, S<:Sensor}
    agent::A
    env::E
    sensor::S
end

"""
    step(sys::System, s)
    step(sys::System, s, D::DisturbanceDistribution)
    step(sys::System, s, x::Disturbance)
    step(sys::System, s, x::NamedTuple)

Progress the system by one time step by
- using `sys.sensor` to make an observation; 
- using `sys.agent` to decide on an action; and
- using `sys.env` to run system dynamics.

If no disturbance is provided, use [`Do`](@ref), [`Da`](@ref), and [`Ds`](@ref)
to sample disturbances.
If disturbance is provided directly via a [`Disturbance`](@ref) or `NamedTuple`,
use those disturbances. If disturbance is provided via a [`DisturbanceDistribution`](@ref)
then sample from that.
"""
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

Generate rollout trajectory of system `sys` by applying [`step(sys, s)`](@ref Base.step)
or [`step(sys, s, x)`](@ref Base.step) at each step.
Returns a vector of steps where each step is a `NamedTuple` `(o, a, s, x)`
or `(o, a, s)`.

Both the initial state and noise trajectory can be optionally provided.

## Examples
```jldoctest rollout
julia> using StanfordAA228V

julia> sys = System(ProportionalController([0, 0]),
                    InvertedPendulum(),
                    IdealSensor());

julia> d = 5;

julia> rollout(sys);

julia> rollout(sys; d=d);
```

# Initial State
The initial state can be provided via `s₀` and is otherwise sampled from [`Ps(sys.env)`](@ref Ps).

```jldoctest rollout
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
julia> pτ = NominalTrajectoryDistribution(sys, 5)  # or another `FuzzingDistribution`

julia> τ1 = rollout(sys, pτ);  # this is effectively the same as `rollout(sys)`

julia> τₓ = [(xo = -0.1 .+ randn(2), xa=nothing, xs=nothing)
             for _ in 1:5];  # we can specify noise trajectory manually

julia> rollout(sys, τₓ);

julia> rollout(sys, s₀, τₓ);  # and we can pass everything at once
```
See [`TrajectoryDistribution`](@ref) for an example to set up your own `FuzzingDistribution` example.
See also [`NominalTrajectoryDistribution`](@ref), [`step`](@ref Base.step).

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
        o, a, s′, x = step(sys, s, D)
        push!(τ, (; s, o, a, x))
        s = s′
    end
    return identity.(τ)  # `identity` converts `Vector{Any}` to concrete vector
end
rollout(sys::System; d=1) = rollout(sys, rand(Ps(sys.env)); d)

"""
    Disturbance

Holds disturbance sample. Interchangable with a NamedTuple with the same names.

# Fields
- `xa` agent disturbance
- `xs` environment disturbance
- `xo` sensor disturbance

See also [`DisturbanceDistribution`](@ref).
"""
struct Disturbance
    xa # agent disturbance
    xs # environment disturbance
    xo # sensor disturbance
end

"""
    DisturbanceDistribution

`struct` holding the disturance distribution for the agent, state, and observations.

# Fields
- `Da`: Agent disturbance distribution with signature `(o)->Distribution`
- `Ds`: Environment disturbance distribution with signature `(s, a)->Distribution`
- `Do`: Sensor disturbance distribution with signature `(s)->Distribution`

# Default Constructor
```julia
function DisturbanceDistribution(sys::System)
    return DisturbanceDistribution((o) -> Da(sys.agent, o),
                                   (s, a) -> Ds(sys.env, s, a),
                                   (s) -> Do(sys.sensor, s))
end
```

See [`TrajectoryDistribution`](@ref) for an example how to use this for a custom fuzzing distribution.
"""
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

"""
    TrajectoryDistribution

A trajectory distribution characterizes the [`initial_state_distribution`](@ref),
[`disturbance_distribution`](@ref), and [`depth`](@ref) of a system rollout.
It is an `abstract type` but can be used to subtype a new distribution.

# Example
```jldoctest
julia> using StanfordAA228V, Distributions, LinearAlgebra

julia> struct MyFuzzingDistribution{S<:System} <: TrajectoryDistribution
         sys::S
         param::Float64
       end;

julia> # IMPORTANT: we have to explicitly import external functions to ovlerload them

julia> import StanfordAA228V: initial_state_distribution, disturbance_distribution, depth

julia> initial_state_distribution(pτ::MyFuzzingDistribution) = Ps(pτ.sys.env);  # system default

julia> disturbance_distribution(pτ::MyFuzzingDistribution, t) = DisturbanceDistribution(
           (o) -> Deterministic(0),  # action noise -> always 0
           (s, a) -> Ds(pτ.sys.env, s, a),  # dynamics noise -> regular system dynamics
           (s) -> MvNormal(
                    mean(Do(sys.sensor, s)),
                    pτ.param*cov(Do(sys.sensor, s))
                  )  # observation noise -> nominal with increase covariance
       );

julia> depth(pτ::MyFuzzingDistribution) = 10;

julia> sys = System(ProportionalController([0, 0]),
                    InvertedPendulum(),
                    AdditiveNoiseSensor(MvNormal(0.1 * I(2))));

julia> τ = rollout(sys, MyFuzzingDistribution(sys, 2.0));
```

See also [`Ps`](@ref), [`Do`](@ref), [`Da`](@ref), [`Ds`](@ref), [`MvNormal`](@extref Distributions.MvNormal).
"""
abstract type TrajectoryDistribution end

"""
    initial_state_distribution(pτ::TrajectoryDistribution)

Used to specify the initial distribution `s₀`.
If [`pτ isa NominalTrajectoryDistribution`](@ref NominalTrajectoryDistribution) this is just [`Ps(sys.env)`](@ref Ps).

See also [`TrajectoryDistribution`](@ref) for an example how to specify this for a custom fuzzing distribution.
"""
function initial_state_distribution end

"""
    disturbance_distribution(pτ::TrajectoryDistribution, t)

Used to specify the disturbance distribution.
If [`pτ isa NominalTrajectoryDistribution`](@ref NominalTrajectoryDistribution) this is just
```julia
DisturbanceDistribution((o) -> Da(sys.agent, o),
                        (s, a) -> Ds(sys.env, s, a),
                        (s) -> Do(sys.sensor, s))
```

See [`TrajectoryDistribution`](@ref) for an example how to specify this for a custom fuzzing distribution.
See also [`Da`](@ref), [`Ds`](@ref), [`Do`](@ref).
"""
function disturbance_distribution end

"""
    depth(p::TrajectoryDistribution)

Specifies number of steps for a trajectory distribution.
See [`TrajectoryDistribution`](@ref) for an example how to specify this for a custom fuzzing distribution.
"""
function depth end

(p::TrajectoryDistribution)(τ) = pdf(p, τ)

"""
    NominalTrajectoryDistribution
"""
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
    return identity.(τ)  # `identity` converts `Vector{Any}` to concrete vector
end
rollout(sys::System, p::TrajectoryDistribution; d=depth(p)) =
    rollout(sys, rand(initial_state_distribution(p)), p; d=d)

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
