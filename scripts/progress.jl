using Distributed
using ProgressMeter

"""
Usage:
    # Launch julia with: -t numthreads

    channel = create_progress(n)

    results = Vector{Bool}(undef, n) # Note {Bool} example

    @threads for i in 1:n
        # some parallel code
        results[i] = some_computed_value
    end

    end_progress(channel)
"""
function create_progress(n)
    progress = Progress(n)
    channel = RemoteChannel(()->Channel{Bool}(), 1)

    @async while take!(channel)
        next!(progress)
    end

    return channel
end

update_progress!(channel) = put!(channel, true) # trigger progress bar update
end_progress(channel) = put!(channel, false) # tell printing task to finish

