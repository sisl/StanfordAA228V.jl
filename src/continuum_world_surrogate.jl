"""
    ContinuumWorldSurrogate <: Environment
"""
@with_kw struct ContinuumWorldSurrogate <: Environment
    cw::ContinuumWorld = ContinuumWorld()
    model # ::Chain
    disturbance_mag = 0.1
end

# Function-like objects
(env::ContinuumWorldSurrogate)(s, a) = env(s, a, rand(Ds(env, s, a)))
(env::ContinuumWorldSurrogate)(s, a, x) = env.model(s) + x # Call neural network to get s′ instead of using the dynamics

Ps(env::ContinuumWorldSurrogate) = Ps(env.cw)

Ds(env::ContinuumWorldSurrogate, s, a) =
    Product([
        Uniform(-env.disturbance_mag, env.disturbance_mag),
        Uniform(-env.disturbance_mag, env.disturbance_mag)])

const Project3LargeSystem::Type = System{NoAgent, ContinuumWorldSurrogate, IdealSensor}
const Project3LargeSystems = Union{Project3LargeSystemOriginal, Project3LargeSystem}

get_depth(sys::Project3LargeSystem) = get_depth(sys.env.cw)
