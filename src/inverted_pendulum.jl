@with_kw struct InvertedPendulum <: Environment
    m::Float64 = 1.0
    l::Float64 = 1.0
    g::Float64 = 10.0
    dt::Float64 = 0.05
    ω_max::Float64 = 8.0
    a_max::Float64 = 2.0
end

function (env::InvertedPendulum)(s, a, xs=missing)
    θ, ω = s[1], s[2]
    dt, g, m, l = env.dt, env.g, env.m, env.l

    a = clamp(a, -env.a_max, env.a_max)

    ω = ω + (3g / (2 * l) * sin(θ) + 3 * a / (m * l^2)) * dt
    θ = θ + ω * dt
    ω = clamp(ω, -env.ω_max, env.ω_max)

    return [θ, ω]
end

Ps(env::InvertedPendulum) = MvNormal(zeros(2), diagm([(π/32)^2, 0.5^2]))

struct AdditiveNoiseSensor <: Sensor
    Do
end

(sensor::AdditiveNoiseSensor)(s) = sensor(s, rand(Do(sensor, s)))
(sensor::AdditiveNoiseSensor)(s, x) = s + x

Do(sensor::AdditiveNoiseSensor, s) = sensor.Do

Os(sensor::AdditiveNoiseSensor) = I

struct ProportionalController <: Agent
    k
end

(c::ProportionalController)(s, a=missing) = c.k' * s
