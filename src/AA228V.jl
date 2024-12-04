module AA228V

using Distributions
using Random
using Statistics
using LinearAlgebra
using Parameters
using ForwardDiff
using Optim
using SignalTemporalLogic
using BSON
using GridInterpolations
using Plots
# import Bijectors: bijector

include("Counted.jl")
using .Counted

export
    Counter,
    increment!,
    reset!,
    @counted,
    @tracked,
    step_counter,
    Agent,
    Environment,
    Sensor,
    System,
    step,
    rollout,
    Disturbance,
    DisturbanceDistribution,
    TrajectoryDistribution,
    initial_state_distribution,
    disturbance_distribution,
    depth,
    NominalTrajectoryDistribution,
    Deterministic,
    Ds,
    Da,
    Do,
    NoAgent,
    SimpleGaussian,
    Ps,
    IdealSensor,
    @formula,
    Specification,
    LTLSpecification,
    evaluate,
    isfailure,
    robustness,
    InvertedPendulum,
    AdditiveNoiseSensor,
    ProportionalController,
    CollisionAvoidance,
    InterpAgent,
    load_cas_policy

include("counter.jl")
include("system.jl")
include("specification.jl")
include("distributions.jl")
include("set_categorical.jl")
include("gaussian_system.jl")
include("inverted_pendulum.jl")
include("cas.jl")

end # module AA228V
