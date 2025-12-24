@with_kw struct MassSpringDamper <: Environment
    m = 1.0
    k = 10.0
    c = 2.0
    dt = 0.05
end

function (env::MassSpringDamper)(s, a, xs=missing)
    return Ts(env) * s + Ta(env) * a
end

Ts(env::MassSpringDamper) = [1 env.dt; -env.k*env.dt/env.m 1-env.c*env.dt/env.m]
Ta(env::MassSpringDamper) = [0 env.dt/env.m]'
Ps(env::MassSpringDamper) = Product([Uniform(-0.2, 0.2), Uniform(-1e-12, 1e-12)])
𝒮₁(env::MassSpringDamper) = Hyperrectangle(low=[-0.2, 0.0], high=[0.2, 0.0])

const Project3SmallSystem::Type = System{ProportionalController, MassSpringDamper, AdditiveNoiseSensor}

get_depth(sys::Project3SmallSystem) = 21