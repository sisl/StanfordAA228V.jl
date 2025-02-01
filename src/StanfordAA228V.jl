module StanfordAA228V

using Pkg
using TOML
using Downloads
using ProgressLogging
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
using LazySets
using Plots
import Interpolations: interpolate as interpolate_spline, CardinalMonotonicInterpolation
import Distances: Euclidean
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
    Os,
    ProportionalController,
    Πo,
    CollisionAvoidance,
    InterpAgent,
    load_cas_policy,
    get_depth,
    MassSpringDamper,
    Ts,
    Ta,
    𝒮₁,
    get_exported_functions,
    check_method_extension,
    Project1,
    Project2,
    Project3,
    tempmodule,
    process,
    @include,
    @load,
    load_backend,
    protected_module,
    notebook_style,
    button_style,
    start_code,
    end_code,
    combine_html_md,
    wrapdiv,
    highlight,
    html_expand,
    html_space,
    html_half_space,
    html_quarter_space,
    aircraft_vertices,
    DarkModeIndicator,
    OpenDirectory,
    LargeCheckBox,
    DarkModeHandler,
    dark_mode_plot,
    compute_cas_lookahead,
    precompute_cas_lookaheads,
    get_aspect_ratio,
    set_aspect_ratio!,
    every_other_xtick!,
    rectangle,
    circle,
    halfcircle,
    rotation,
    scaled,
    rotation_from_points,
    mirror_horizontal,
    get_version,
    validate_version,
    validate_project_version,
    guess_username,
    @conditional_progress,
    ndigits,
    expnum,
    format,
    info,
    hint,
    almost,
    keep_working,
    correct,
    Columns,
    get_filename,
    env_name,
    system_name,
    submission_details,
    textbook_details,
    baseline_details,
    depth_highlight,
    AvoidSetSpecification,
    ¬,
    disturbance_set,
    subset_vertices,
    extract_set,
    count_vertices,
    fan_sets,
    plot_optimal,
    plot_msd_time_axis,
    plot_msd_traj!,
    plot_pendulum_state,
    plot_pendulum_solution,
    plot_pendulum_solution!,
    ContinuumWorld,
    load_cw_policy,
    ContinuumWorldSurrogate,
    NeuralNetworkAgent,
    plot_cw_trajectory!,
    cw_success_and_failure,
    cw_generate_trajectory,
    SetCategorical,
    plotsamples!,
    plotoutsiders!,
    plotting_vertices,
    compute_volume,
    plotset,
    plotset!,
    bounded_set,
    bounded_wrapper,
    precompute_soundness_and_outsiders,
    plot_cw_full_reachability,
    plot_cw_reachability

include("system.jl")
include("specification.jl")
include("distributions.jl")
include("set_categorical.jl")
include("reachability.jl")
include("gaussian_system.jl")
include("inverted_pendulum.jl")
include("cas.jl")
include("mass_spring_damper.jl")
include("continuum_world.jl")
include("continuum_world_surrogate.jl")
include("notebook/backend.jl")
include("notebook/html.jl")
include("notebook/aircraft_svg.jl")
include("notebook/bindings.jl")
include("notebook/utils.jl")
include("notebook/plotting.jl")
include("notebook/versioning.jl")
include("notebook/leaderboard.jl")
include("notebook/markdown.jl")
include("notebook/details.jl")

end # module StanfordAA228V
