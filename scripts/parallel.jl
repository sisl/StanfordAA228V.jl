using Base.Threads
using Distributed

include("progress.jl")
include(joinpath(@__DIR__, "..", "..", "AA228VProjects", "project1", "project1.jl")) # has the same systems as project2.jl

using BSON

function monte_carlo_truth(sys, ψ; n=max_steps(sys), filename="tmp.bson")
    @info "Number of threads: $(nthreads())"

    d = get_depth(sys)
    pτ = NominalTrajectoryDistribution(sys, d)
    m = n ÷ d

    if isfile(filename)
        @info "Loading previous results to combine."
        pfail_prev, _, m_prev = BSON.load(filename)[:results]
        num_failures_prev = 0
        try
            num_failures_prev = Int(pfail_prev * m_prev)
        catch err
            @warn err
            num_failures_prev = round(Int, pfail_prev * m_prev) # Precision issue
        end
    else
        num_failures_prev = 0
        m_prev = 0
    end

    channel = create_progress(m)

    𝟙 = Vector{Bool}(undef, m)

    @threads for seed in 1:m
        Random.seed!(seed + m_prev) # NOTE: offset when adding more samples
        τ = rollout(sys, pτ; d)
        update_progress!(channel)
        𝟙[seed] = isfailure(ψ, τ)
    end

    end_progress(channel)

    num_failures = sum(𝟙)

    num_failures_combined = num_failures + num_failures_prev
    m_combined = m + m_prev
    pfail_combined = num_failures_combined / m_combined
    pfail_combined_std = sqrt(pfail_combined / m_combined)

    results = (pfail_combined, pfail_combined_std, m_combined)

    BSON.@save filename results
    @show results

    return results
end

# precompile runs
rm("tmp.bson"; force=true)
monte_carlo_truth(sys_medium, ψ_medium; n=10_000)
monte_carlo_truth(sys_large, ψ_large; n=10_000)

n_medium = Int(41*25_000_000)
filename_medium = "truth_medium.bson"
results_medium = monte_carlo_truth(sys_medium, ψ_medium; n=n_medium, filename=filename_medium)

n_large = Int(41*75_000_000)
filename_large = "truth_large.bson"
results_large = monte_carlo_truth(sys_large, ψ_large; n=n_large, filename=filename_large)
