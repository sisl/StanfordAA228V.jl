abstract type Agent end
abstract type Environment end
abstract type Sensor end

struct System
    agent::Agent
    env::Environment
    sensor::Sensor
end

function step(sys::System, s)
    o = sys.sensor(s)
    a = sys.agent(o)
    s′ = sys.env(s, a)
    return (; o, a, s′)
end

function rollout(sys::System; d)
    s = rand(Ps(sys.env))
    τ = []
    for t in 1:d
        o, a, s′ = step(sys, s)
        push!(τ, (; s, o, a))
        s = s′
    end
    return τ
end
