@with_kw struct CollisionAvoidance <: Environment
    ddh_max::Float64 = 1.0 # [m/s²]
    𝒜::Vector{Float64} = [-5.0, 0.0, 5.0] # [m/s]
    Ds::Sampleable = Normal()
end

Ds(env::CollisionAvoidance, s, a) = env.Ds

function (env::CollisionAvoidance)(s, a, x)
    a = env.𝒜[a]

    h, dh, a_prev, τ = s

    h = h + dh

    if a != 0.0
        if abs(a - dh) < env.ddh_max
            dh += a
        else
            dh += sign(a - dh) * env.ddh_max
        end
    end

    a_prev = a
    τ = max(τ - 1.0, -1.0)

    return [h, dh + x, a_prev, τ]
end

(env::CollisionAvoidance)(s, a) = env(s, a, rand(Ds(env, s, a)))

Ps(env::CollisionAvoidance) = product_distribution(Uniform(-100, 100), Uniform(-10, 10), DiscreteNonParametric([0], [1.0]), DiscreteNonParametric([40], [1.0]))

struct InterpAgent <: Agent
    grid::RectangleGrid
    Q
end

(c::InterpAgent)(s) = argmax([interpolate(c.grid, q, s) for q in c.Q])
(c::InterpAgent)(s, x) = c(s)

Distributions.pdf(c::InterpAgent, o, xₐ) = 1.0

function load_cas_policy(filename::String)
    res = BSON.load(filename)
	grid = res[:grid]
	Q = res[:Q]
    return grid, Q
end
