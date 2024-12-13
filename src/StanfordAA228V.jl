module StanfordAA228V

using Pkg
using Distributions
using Random
using Statistics
using LinearAlgebra
using Parameters
using ForwardDiff
using Optim
using SignalTemporalLogic
using AbstractPlutoDingetjes
using Markdown
using Base64
using BSON
using GridInterpolations
using Plots
# import Bijectors: bijector

include("Counted.jl")
using .Counted

export
    Counted,
    @tracked,
    @small,
    @medium,
    @large,
    stepcount,
    InvalidSeeders,
    check_stacktrace_for_invalids,
    Agent,
    Environment,
    Sensor,
    System,
    step,
    rollout,
    mean_step,
    mean_rollout,
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
    load_cas_policy,
    get_exported_functions,
    check_method_extension,
    Project1,
    Project2,
    tmpmodule,
    process,
    @include,
    start_code,
    end_code,
    combine_html_md,
    html_expand,
    html_space,
    html_half_space,
    html_quarter_space,
    aircraft_vertices,
    DarkModeIndicator,
    OpenDirectory,
    LargeCheckBox,
    get_aspect_ratio,
    set_aspect_ratio!,
    rectangle,
    circle,
    halfcircle,
    rotation,
    scaled,
    rotation_from_points,
    mirror_horizontal,
    get_version,
    validate_version,
    guess_username,
    expnum,
    format,
    info,
    hint,
    almost,
    keep_working,
    correct

include("system.jl")
include("specification.jl")
include("distributions.jl")
include("set_categorical.jl")
include("gaussian_system.jl")
include("inverted_pendulum.jl")
include("cas.jl")
include("notebook/backend.jl")
include("notebook/html.jl")
include("notebook/aircraft_svg.jl")
include("notebook/widgets.jl")
include("notebook/plotting.jl")
include("notebook/versioning.jl")
include("notebook/leaderboard.jl")
include("notebook/utils.jl")
include("notebook/markdown.jl")

end # module StanfordAA228V
