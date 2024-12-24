abstract type Agent end
abstract type Environment end
abstract type Sensor end

struct System{A<:Agent, E<:Environment, S<:Sensor}
    agent::A
    env::E
    sensor::S
end

@counted function step(sys::System, s)
    o = sys.sensor(s)
    a = sys.agent(o)
    s′ = sys.env(s, a)
    return (; o, a, s′)
end

function rollout(sys::System; d=1)
    s = rand(Ps(sys.env))
    τ = []
    for t in 1:d
        o, a, s′ = step(sys, s)
        push!(τ, (; s, o, a))
        s = s′
    end
    return τ
end

function rollout(sys::System, s; d)
	τ = []
	for t in 1:d
		o, a, s′ = step(sys, s)
		push!(τ, (; s, o, a))
		s = s′
	end
	return τ
end

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

@counted function step(sys::System, s, D::DisturbanceDistribution)
    xo = rand(D.Do(s))
    o = sys.sensor(s, xo)
    xa = rand(D.Da(o))
    a = sys.agent(o, xa)
    xs = rand(D.Ds(s, a))
    s′ = sys.env(s, a, xs)
    x = Disturbance(xa, xs, xo)
    return (; o, a, s′, x)
end

abstract type TrajectoryDistribution end
function initial_state_distribution(p::TrajectoryDistribution) end
function disturbance_distribution(p::TrajectoryDistribution, t) end
function depth(p::TrajectoryDistribution) end

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

@counted function step(sys::System, s, x)
    o = sys.sensor(s, x.xo)
    a = sys.agent(o, x.xa)
    s′ = sys.env(s, a, x.xs)
    return (; o, a, s′)
end

function rollout(sys::System, s, 𝐱; d=length(𝐱))
    τ = []
    for t in 1:d
        x = 𝐱[t]
        o, a, s′ = step(sys, s, x)
        push!(τ, (; s, o, a, x))
        s = s′
    end
    return τ
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

function rollout(sys::System, p::TrajectoryDistribution; d=depth(p))
    s = rand(initial_state_distribution(p))
    τ = []
    for t = 1:d
        o, a, s′, x = step(sys, s, disturbance_distribution(p, t))
        push!(τ, (; s, o, a, x))
        s = s′
    end
    return τ
end

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
