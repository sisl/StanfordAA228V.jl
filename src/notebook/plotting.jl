module DarkModeHandler
    dark_mode = false

    function setdarkmode!(value::Bool)
        global dark_mode = value
    end

    getdarkmode() = dark_mode
    toggledarkmode!() = setdarkmode!(!dark_mode)
end

using .DarkModeHandler

global PASTEL_RED = "#F5615C"
global PASTEL_GREEN = "#009E73"
global PASTEL_SKY_BLUE = "#56B4E9"
global PASTEL_PURPLE = "#8770FE"
global DARK_MODE_BACKGROUND = "#1A1A1A"
global LIGHT_MODE_BACKGROUND = "#FFFFFF"

function dark_mode_plot(is_dark_mode=false; bghexalpha="", hold=false, kwargs...)
    bgcolor = is_dark_mode ? string(DARK_MODE_BACKGROUND, bghexalpha) : string(LIGHT_MODE_BACKGROUND, bghexalpha)
    _plot = hold ? plot! : plot
    _plot(;
        bg="transparent",
        background_color_inside=bgcolor,
        bglegend=bgcolor,
        fg=is_dark_mode ? "white" : "black",
        gridalpha=is_dark_mode ? 0.5 : 0.1,
        kwargs...
    )
end

function plot_pfail_histogram(sys, ψ, 𝐏;
                               f_truth::Function,
                               baseline::Float64,
                               is_dark_mode=DarkModeHandler.getdarkmode())
    dark_mode_plot(is_dark_mode;
        bghexalpha="66",
        legend_foreground_color=:black,
		foreground_color_border=:black,
		foreground_color_axis=:black,
        gridalpha=0.1,
    )

	histogram!(𝐏;
		size=(400,250),
		xlabel="""

		\$\\hat{P}_\\mathrm{fail}\$ estimates""",
		ylabel="frequency\n",
        titlefontsize=10,
		labelfontsize=8,
		tickfontsize=6,
		legendfontsize=6,
		label=false,
		color=:lightgray,
		linecolor=:black,
		rightmargin=8Plots.mm,
		leftmargin=0Plots.mm,
		bottommargin=-5Plots.mm,
		topmargin=0Plots.mm,
		legend=:topright,
	)
	vline!([f_truth(sys, ψ)];
		color=:crimson,
		label="truth",
		lw=2,
	)
	vline!([baseline];
		color="#017E7C",
		label="baseline",
		lw=2,
		ls=:dashdot,
	)
	vline!([mean(𝐏)];
		color="#FEC51D",
		label="mean estimate",
		lw=2,
		ls=:dash,
	)
	# every_other_xtick!()
	ylims!(0, ylims()[2]*1.05)
	set_aspect_ratio!()
end

########################################
## SmallSystem: Projects 1 & 2
##     Simple Gaussian
########################################

function Plots.plot(sys::Project1SmallSystem, ψ, τ=missing;
					is_dark_mode=DarkModeHandler.getdarkmode(),
                    max_points=500, bghexalpha="",
                    kwargs...)
	ps = Ps(sys.env)

    dark_mode_plot(is_dark_mode; bghexalpha)

	# Create a range of x values
	_X = range(-4, 4, length=1000)
	_Y = pdf.(ps, _X)

	# Plot the Gaussian density
	plot!(_X, _Y;
	     xlim=(-4, 4),
	     ylim=(-0.001, 0.41),
	     linecolor=is_dark_mode ? "white" : "black",
		 fillcolor=is_dark_mode ? "darkgray" : "lightgray",
		 fill=true,
	     xlabel="state \$s\$",
	     ylabel="density \$p(s)\$",
	     size=(600, 300),
	     label=false,
         kwargs...)

	# Identify the indices where x ≤ c or x ≥ c
	c = ψ.formula.ϕ.c

	if ψ.formula.ϕ isa Predicate
		idx = _X .≤ c
	else
		idx = _X .≥ c
	end

	# Extract the x and y values for the region to fill
	x_fill = _X[idx]
	y_fill = _Y[idx]

	# Create the coordinates for the filled polygon
	# Start with the x and y values where x <= -2
	# Then add the same x values in reverse with y = 0 to close the polygon
	polygon_x = vcat(x_fill, reverse(x_fill))
	polygon_y = vcat(y_fill, zeros(length(y_fill)))

	# Add the filled area to the plot
	plot!(polygon_x, polygon_y,
	      fill=true,
	      fillcolor="crimson",
	      linecolor="transparent", # No border for the filled area
		  alpha=0.5,
	      label=false)

	# Draw failure threshold
	vline!([c]; color="crimson", legend=:topleft, label="Failure threshold")

	if !ismissing(τ)
		count_plotted_succeses = 0
		count_plotted_failures = 0
		function plot_point!(τᵢ)
			if isfailure(ψ, τᵢ) && count_plotted_failures == 0
				label = "Failure state"
				count_plotted_failures += 1
			elseif !isfailure(ψ, τᵢ) && count_plotted_succeses == 0
				label = "Success state"
				count_plotted_succeses += 1
			else
				label = false
			end
			color = isfailure(ψ, τᵢ) ? "red" : PASTEL_GREEN
			τₓ = τᵢ[1].s[1]
			scatter!([τₓ], [pdf(ps, τₓ)], color=color, msc="white", m=:circle, label=label)
		end

		if τ isa Vector{<:Vector}
			# Multiple rollouts
			success_points = 0
			for τᵢ in τ
				is_fail = isfailure(ψ, τᵢ)
				if is_fail
					plot_point!(τᵢ)
				elseif success_points ≤ max_points
					success_points += 1
					plot_point!(τᵢ)
				end
			end
		elseif τ isa Vector
			# Single rollout
			plot_point!(τ)
		end
	end

	return plot!()
end


function plot_cdf(sys::Project1SmallSystem, ψ; is_dark_mode=DarkModeHandler.getdarkmode())
	ps = Ps(sys.env)

    dark_mode_plot(is_dark_mode;
		xlim=(-4, 4),
		ylim=(-0.001, 1.05),
		linecolor=is_dark_mode ? "white" : "black",
		fillcolor=is_dark_mode ? "darkgray" : "lightgray",
		fill=true,
		xlabel="state \$s\$",
		ylabel="cumulative probability density",
		size=(600, 300),
		label=false,
	)
	primary_color = is_dark_mode ? "white" : "black"
	dash_color = "crimson"

	_X = range(-4, 4, length=1000)
	_Y = cdf.(ps, _X)

	plot!(_X, _Y;
		  linecolor=is_dark_mode ? "white" : "black",
		  fillcolor=is_dark_mode ? "darkgray" : "lightgray",
		  fill=true,
	      label=false, color=primary_color)

	c = ψ.formula.ϕ.c
	Pc = cdf(ps, ψ.formula.ϕ.c)

	plot!([c, c], [0, Pc];
        ls=:dash, color=dash_color, label=false)
	plot!([-4, c], fill(Pc, 2);
        ls=:dash, color=dash_color, label=false)
    scatter!([c], [Pc];
        color=dash_color, label=false, ms=3)

	return plot!()
end


########################################
## MediumSystem: Projects 1 & 2
##     Inverted Pendulum
########################################
function Plots.plot(sys::Project1MediumSystem, ψ, τ=missing;
                    is_dark_mode=DarkModeHandler.getdarkmode(),
					title="Inverted Pendulum",
					max_lines=100, size=(680,350), kwargs...)

    dark_mode_plot(is_dark_mode; size, grid=false)
	plot!(rectangle(2, 1, 0, π/4), opacity=0.5, color=PASTEL_RED, label=false)
	plot!(rectangle(2, 1, 0, -π/4-1), opacity=0.5, color=PASTEL_RED, label=false)
	xlabel!("Time (s)")
	ylabel!("𝜃 (rad)")
	title!(title)
	xlims!(0, 2)
	ylims!(-1.2, 1.2)
	set_aspect_ratio!()

	function plot_pendulum_traj!(τ; lw=2, α=1, color=PASTEL_GREEN)
		X = range(0, step=sys.env.dt, length=length(τ))
		plot!(X, [step.s[1] for step in τ]; lw, color, α, label=false)
	end

	if τ isa Vector{<:Vector}
		# Multiple trajectories
		τ_successes = filter(τᵢ->!isfailure(ψ, τᵢ), τ)
		τ_failures = filter(τᵢ->isfailure(ψ, τᵢ), τ)
		for (i,τᵢ) in enumerate(τ_successes)
			if i > max_lines
				break
			else
				plot_pendulum_traj!(τᵢ; lw=1, α=0.25, color=PASTEL_GREEN)
			end
		end

		for τᵢ in τ_failures
			plot_pendulum_traj!(τᵢ; lw=2, α=1, color=PASTEL_RED)
		end
	elseif τ isa Vector
		# Single trajectory
		get_color(ψ, τ) = isfailure(ψ, τ) ? PASTEL_RED : PASTEL_GREEN
		plot_pendulum_traj!(τ; lw=2, color=get_color(ψ, τ))
	end

    return plot!()
end


function plot_pendulum(θ; c=π/4, is_dark_mode=DarkModeHandler.getdarkmode(), title="", kwargs...)
    dark_mode_plot(is_dark_mode;
        grid=false,
        axis=false,
        title=title,
		background_color_inside=:transparent,
        kwargs...
    )
	l = 3 # Pendulum length
	r = l/3
	buffer = 1.05 # Axis limit buffer
	lt = 1.1r # Failure threshold length

	xlims!(-l*buffer, l*buffer)
	ylims!(-l*buffer, l*buffer)
	set_aspect_ratio!()

	# Background circle
	plot!(circle([0,0], r), seriestype=:shape, color="#b9e2d5", lc="transparent", label=false)

	# Failure regions
	plot!(halfcircle([0,0], r, c), seriestype=:shape, color="#fbdfdc", lc="transparent", label=false)

	plot!(halfcircle([0,0], r, -c), seriestype=:shape, color="#fbdfdc", lc="transparent", label=false)

	# Outline
	plot!(circle([0,0], r), seriestype=:shape, color="transparent", lc="transparent", label=false)

	# Failure thresholds
	plot!([0, lt*sin(c)], [0, lt*cos(c)], color="#F5615C", ls=:dash, lw=2, label=false)

	plot!([0, lt*sin(-c)], [0, lt*cos(-c)], color="#F5615C", ls=:dash, lw=2, label=false)

	# Pendulum
	topx = l * sind(θ)
	topy = l * cosd(θ)

	pend_color = θ < -rad2deg(c) || θ > rad2deg(c) ? "#F5615C" : "#417865"
	plot!([0, topx], [0, topy], lw=3, color=pend_color, label=false)

	# Center point
	scatter!([0], [0], marker=:circle, ms=5, color="black", label=false)
end


########################################
## LargeSystem: Projects 1 & 2
##     Collision avoidance system (CAS)
########################################

Plots.plot!(sys::Project1LargeSystem, ψ, τ=missing; kwargs...) = plot(sys, ψ, τ; hold=true, kwargs...)
function Plots.plot(sys::Project1LargeSystem, ψ, τ=missing;
                    is_dark_mode=DarkModeHandler.getdarkmode(),
                    t=missing, max_lines=100, max_lines_include_failure=false,
                    flw=2, fα=1, sα=0.25, slw=1, size=(680,350), title="", hold=false, aircraft_color="black", kwargs...)

    dark_mode_plot(is_dark_mode;
        hold,
        size,
        grid=false,
        xflip=true,
        kwargs...
    )

    primary_color = is_dark_mode ? "white" : "black"

    xlims!(0, 40)
    ylims!(-400, 400)
    set_aspect_ratio!()
    ratio = get_aspect_ratio()
    xlabel!("\$t_\\mathrm{col}\$ (s)")
    ylabel!("\$h\$ (m)")
    title!(title)

    # Collision region
    plot!(rectangle(1, 100, 0, -50), opacity=0.5, color=PASTEL_RED, label=false)

    # Intruder
    shape_scale = 0.03
    intruder_shape = scaled(Shape(mirror_horizontal(aircraft_vertices)), shape_scale)
    marker = (intruder_shape, 1, "black")
    scatter!([1.5], [0]; color=primary_color, msc=primary_color, marker=marker, ms=4, label=false)

    function plot_cas_traj!(τ; lw=flw, α=fα, color=PASTEL_GREEN)
        t′ = ismissing(t) ? 41 : t
        X = reverse(range(41-t′, 40, length=t′))
        H = [step.s[1] for step in τ[1:t′]]
        plot!(X, H; lw, color, α, label=false)
        if !ismissing(t)
            if t ≤ 0
                error("Time should be t > 0")
            else
                # Important: undo xflip (41-x) and apply aspect ratio to the y values
                if t == 1
                    # Look ahead +1 to get proper angle for t=1
                    t′′ = t′+t+1
                    X′ = reverse(range(41-t′′, 40, length=t′′))
                    H′ = [step.s[1] for step in τ[1:t′′]]
                    p1 = (41-X′[t′′-1], H′[t′′-1]*ratio)
                    p2 = (41-X′[t′′], H′[t′′]*ratio)
                else
                    p1 = (41-X[t-1], H[t-1]*ratio)
                    p2 = (41-X[t], H[t]*ratio)
                end
                θ = rotation_from_points(p1, p2)
                shape = scaled(rotation(Shape(aircraft_vertices), θ), shape_scale)
                marker = (shape, 1, aircraft_color)
                scatter!([X[end]], [H[end]]; color=primary_color, msc=primary_color, α, marker=marker, ms=4, label=false)
            end
        end
    end

    if τ isa Vector{<:Vector}
        # Multiple trajectories
        num_lines = 0
        for τᵢ in τ
            failed = isfailure(ψ, τᵢ)
            if failed
                if max_lines_include_failure && num_lines > max_lines
                    continue
                else
                    plot_cas_traj!(τᵢ; lw=flw, α=fα, color=PASTEL_RED)
                    if max_lines_include_failure
                        num_lines += 1
                    end
                end
            else
                if num_lines > max_lines
                    continue
                else
                    plot_cas_traj!(τᵢ; lw=slw, α=sα, color=PASTEL_GREEN)
                    num_lines += 1
                end
            end
        end
    elseif τ isa Vector
        # Single trajectory
        get_color(ψ, τ) = isfailure(ψ, τ) ? PASTEL_RED : "#009E73"
        plot_cas_traj!(τ; lw=flw, α=fα, color=get_color(ψ, τ))
    end

    return plot!()
end


function compute_cas_lookahead(sys::Project1LargeSystem, ψ, τ, t; seed=4, n_lookahead=100)
    Random.seed!(seed)
    s = τ[t].s
    d = get_depth(sys)

    τs_lookahead = [rollout(sys, s; d=d-t+1) for i in 1:n_lookahead]
    for i in eachindex(τs_lookahead)
        τs_lookahead[i] = vcat(τ[1:t-1], τs_lookahead[i])
    end
    pfail_lookahead = mean(isfailure.(ψ, τs_lookahead))
    pfail_lookahead_var = var(isfailure.(ψ, τs_lookahead))

    return τs_lookahead, pfail_lookahead, pfail_lookahead_var
end


function precompute_cas_lookaheads(sys::Project1LargeSystem, ψ, τ;
                                   seed=4, n_lookahead=100,
                                   show_progress=true)
    τs_lookaheads = []
    pfails = []
    pfails_var = []
    d = get_depth(sys)
    @conditional_progress show_progress for t in 1:d
        τs_lookahead, pfail_lookahead, pfail_lookahead_var =
            compute_cas_lookahead(sys, ψ, τ, t; seed, n_lookahead)
        push!(τs_lookaheads, τs_lookahead)
        push!(pfails, pfail_lookahead)
        push!(pfails_var, pfail_lookahead_var)
    end
    return τs_lookaheads, pfails, pfails_var
end


function plot_cas_lookahead(sys::Project1LargeSystem, ψ, τ;
                            t=1,
                            n_lookahead=100,
                            digits=numdigits(n_lookahead),
                            seed=4,
                            is_dark_mode=DarkModeHandler.getdarkmode(),
                            show_progress=false,
                            max_lines=100,
                            flw=1,
                            fα=0.5,
                            slw=1,
                            sα=0.25,
                            kwargs...)
    τs_lookaheads, pfails, pfails_var = precompute_cas_lookaheads(sys, ψ, τ; n_lookahead, seed, show_progress)
    plot_cas_lookahead(sys, ψ;
        τ, τs=τs_lookaheads, pfails, pfails_var,
        t, digits, is_dark_mode, max_lines,
        flw, fα, slw, sα, kwargs...)
end


function plot_cas_lookahead(sys::Project1LargeSystem, ψ;
                            τ=missing,
                            τs=missing,
                            pfails=missing,
                            pfails_var=missing,
                            t=1,
                            digits=numdigits(length(τs[1])),
                            max_lines=100,
                            flw=1,
                            fα=0.5,
                            slw=1,
                            sα=0.25,
                            is_dark_mode=DarkModeHandler.getdarkmode(),
                            kwargs...)
    if ismissing(τ)
        error("plot_cas_lookahead: Please provide the precomputed CAS trajectory τ")
    end

    if ismissing(τs)
        error("plot_cas_lookahead: Please provide a set of precomputed CAS trajectories τs")
    end

    if ismissing(pfails)
        error("plot_cas_lookahead: Please provide a set of precomputed CAS `pfails`")
    end

    if ismissing(pfails_var)
        error("plot_cas_lookahead: Please provide a set of precomputed CAS `pfails_var`")
    end

    d = get_depth(sys)

    plot(
        begin
            plot(sys, ψ, τs[t];
                is_dark_mode, max_lines, max_lines_include_failure=true,
                flw, fα, slw, sα, dpi=300)

            plot!(sys, ψ, τ;
                t=t,
                is_dark_mode,
                title="\$P_\\mathrm{fail}\$ ≈ $(round(pfails[t]; digits))",
                titlefontsize=12,
                dpi=300)
        end,
        begin
            px = d .- (1:t)
            py = pfails[1:t]
            pvar = pfails_var[1:t]
            fail_color = PASTEL_RED
            dark_mode_plot(is_dark_mode)
            plot!(px, py;
                ribbon=pvar,
                fillcolor=fail_color,
                fillalpha=0.1,
                color=fail_color,
                lw=2,
                label=false,
                size=(680,350),
                grid=false,
                xflip=true,
                titlefontsize=12,
                xlims=(0, 40),
                ylims=(-0.01, 1.01),
                xlabel="\$t_\\mathrm{col}\$ (s)",
                ylabel="\$P_\\mathrm{fail}\$",
                title="Failure probability estimate",
                kwargs...
            )
            plot!(px, py .+ pvar; color=fail_color, lw=0.2, label=false)
            plot!(px, py .- pvar; color=fail_color, lw=0.2, label=false)
            set_aspect_ratio!()
        end,
        dpi=300, size=(680, 330),
        leftmargin=3Plots.mm, rightmargin=3Plots.mm,
        layout=(1,2),
    )
end


########################################
## Plotting utilities
########################################

function get_aspect_ratio()
    x_range = xlims()[2] - xlims()[1]
    y_range = ylims()[2] - ylims()[1]
    return x_range/y_range
end

function set_aspect_ratio!()
    ratio = get_aspect_ratio()
    plot!(ratio=ratio)
end

function every_other_xtick!()
	xtick_values, xtick_labels = xticks(plot!())[1]
	xticks!(plot!(), xtick_values[1:2:end], xtick_labels[1:2:end])
end

rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])

function circle(xy::Vector, r::Real)
    θ = LinRange(0, 2π, 500)
    return xy[1] .+ r*sin.(θ), xy[2] .+ r*cos.(θ)
end

function halfcircle(xy::Vector, r::Real, threshold)
    θ = LinRange(-π/2, π/2, 500) .+ 3threshold
    return xy[1] .+ r*sin.(θ), xy[2] .+ r*cos.(θ)
end

function rotation(s::Shape, θd)
    x = s.x
    y = s.y
    xr = x .* cosd(θd) .- y .* sind(θd)
    yr = x .* sind(θd) .+ y .* cosd(θd)
    return Shape(xr, yr)
end

function scaled(s::Shape, scale=1)
    return Shape(s.x .* scale, s.y .* scale)
end

function rotation_from_points(p1, p2)
    dx = p2[1] - p1[1]
    dy = p2[2] - p1[2]
    θ = atand(dy, dx)
    return θ
end

mirror_horizontal(points::Vector) = [(-p[1], p[2]) for p in points]

function Plots.plot(sys::Project3SmallSystem, ψ;
                    is_dark_mode=DarkModeHandler.getdarkmode(),
					title="",
					max_lines=100, size=(400,350), kwargs...)

	dark_mode_plot(is_dark_mode;
		size,
		grid=false,
		title,
		titlefontsize=12,
		bottommargin=5Plots.mm)

	plot!(¬ψ; opacity=0.5, color=PASTEL_RED, label=false, gridcolor=is_dark_mode ? DARK_MODE_BACKGROUND : LIGHT_MODE_BACKGROUND) # Hack for gridcolor

	xlabel!("""

	\$p\$ (m)""")
	ylabel!("\$v\$ (m/s)")
	xlims!(-0.6, 0.6)
	ylims!(-0.6, 0.6)
	set_aspect_ratio!()

    return plot!(rightmargin=12Plots.mm)
end

SmallSetType = Union{UnionSet, LazySet, Vector{<:LazySet}}

plot_optimal!(sys::Project3SmallSystem, ψ::AvoidSetSpecification, ℛ::SmallSetType; kwargs...) = plot_optimal(sys, ψ, ℛ; hold=true, kwargs...)
function plot_optimal(sys::Project3SmallSystem, ψ::AvoidSetSpecification, ℛ::SmallSetType;
                      is_dark_mode=DarkModeHandler.getdarkmode(),
                      size=(650,350),
                      sigdigits=4,
					  ℛt=missing,
                      plot_sys=true,
                      hold=true,
					  include_legend=true,
                      kwargs...)
	rdpad = x->rpad(round(x; sigdigits), 6, '0')

    if plot_sys
        plot(sys, ψ; is_dark_mode)
    end

    _plot = hold ? plot! : plot

	if ismissing(ℛt)
	    optimal_set = convex_hull(ℛ)
		label = "$(rdpad(LazySets.volume(optimal_set))) (optimal volume)"
	else
		label = false
		optimal_set = ℛt
	end

    # _plot(optimal_set;
	plotset(optimal_set;
		hold,
        mark=false,
        c=:lightgray,
        fillalpha=0.15,
        lw=1,
        ls=:dash,
        lc=:lightgray,
        linealpha=1,
        label)

	if include_legend
	    return plot!(; legend=:outertopright, size=size, kwargs...)
	else
	    return plot!(; legend=false, size=size, kwargs...)
	end
end

function Plots.plot(sys::Project3SmallSystem, ψ::AvoidSetSpecification, ℛ::SmallSetType;
                    is_dark_mode=DarkModeHandler.getdarkmode(),
					ℛ_linear=missing,
					t=missing,
					ℛt=missing,
					show_samples=false,
                    return_time_plot=false,
					τs=missing,
					issound=[true],
					outsiders=missing,
                    size=(650,350),
					sigdigits=4,
					kwargs...)

	rdpad = x->rpad(round(x; sigdigits), 6, '0')
	if typeof(ℛ) <: Vector
		ch_student = convex_hull(UnionSetArray(ℛ))
	else
		ch_student = convex_hull(ℛ)
	end

	intersected_failure = !is_intersection_empty(ch_student, ψ.set)

    local 𝐫 = missing
    if !ismissing(t) || return_time_plot
		try
			𝐫 = extract_set(ℛ)
        catch err
            @warn err
        end
    end

	if show_samples && !ismissing(τs)
		Random.seed!(0)
		# τs = [rollout(sys, d=d+1) for _ in 1:num_samples]

		function plot_samples!(t; show_label=false, ms=2)
			scatter!([τ[t].s[1] for τ in τs], [τ[t].s[2] for τ in τs];
				ms,
				color=PASTEL_SKY_BLUE,
				msc=PASTEL_SKY_BLUE,
				label=show_label ? "trajectory samples" : false)
		end
	end

	if !return_time_plot
		plt1 = plot(sys, ψ; is_dark_mode)

		if !ismissing(ℛ_linear)
			plot_optimal!(sys, ψ, ℛ_linear; plot_sys=false)
		end

		plot!(ch_student;
			color=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
			mark=false,
			lc=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
			lw=2,
			linealpha=1,
			fillalpha=0.15,
			label="$(rdpad(LazySets.volume(ch_student))) (your volume)")

		if !ismissing(t) && !return_time_plot
			try
				local intersected_failure = !is_intersection_empty(𝐫, ψ.set)
				plot!(𝐫[t];
					color=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
					mark=false,
					lc=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
					lw=1,
					linealpha=1,
					fillalpha=0.15)
			catch err
				@warn err
			end
		end

		if show_samples
			if !return_time_plot
				if ismissing(t)
					d = get_depth(sys)
					for t in 1:d+1
						plot_samples!(t; show_label=(t==1))
					end
				else
					plot_samples!(t; show_label=true)
				end
			end
		end

		plot!(legend=:outertopright, size=size)

		return plt1
    else
        # Include title on first plot if second plot is also shown
        plot!(title="Convex hull over all time steps", titlefontsize=10)

        plt2 = plot(sys, ψ)
        plot!(title="Reachable sets per time step", titlefontsize=10)

        plot!(ch_student;
            color=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
            fillalpha=0.15,
            lw=1,
            ls=:dash,
            lc=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
            linealpha=1,
            label=false)
            # label="$(rdpad(LazySets.volume(ch_student))) (your volume)")

        if !ismissing(𝐫)
            r_t = missing
            r_t_intersected_failure = missing
            if !(𝐫 isa Array)
                𝐫 = [𝐫]
                r_t = 𝐫[1]
                r_t_intersected_failure = !is_intersection_empty(𝐫[1], ψ.set)
            end
            for (tᵣ, r) in enumerate(𝐫)
                local intersected_failure = !is_intersection_empty(r, ψ.set)
                if !ismissing(t) && tᵣ == t
                    r_t = r
                    r_t_intersected_failure = intersected_failure
                end
                # Could plot ℛ directly but this lacks control over each set color.
                plot!(r;
                    color=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
                    mark=false,
                    lc=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
                    lw=2,
                    linealpha=0.5,
                    fillalpha=0.05)
            end

            if !ismissing(r_t)
				plt3 = plot(sys, ψ)

				if !ismissing(ℛ_linear)
					plot_optimal!(sys, ψ, ℛ_linear; plot_sys=false, include_legend=false, ℛt)
				end
		
                plot!(title="Reachable set at time \$t = $t\$", titlefontsize=10)
                plot!(r_t;
                    color=r_t_intersected_failure ? PASTEL_RED : PASTEL_GREEN,
                    mark=false,
                    lc=r_t_intersected_failure ? PASTEL_RED : PASTEL_GREEN,
                    lw=1,
                    linealpha=1,
                    fillalpha=0.15,
                    label=false)
                plot!(ch_student;
                    color=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
                    fillalpha=0.15,
                    lw=1,
                    ls=:dash,
                    lc=intersected_failure ? PASTEL_RED : PASTEL_GREEN,
                    linealpha=1,
                    label=false)

                plot_samples!(t; ms=1)

				if !all(issound)
					plotoutsiders!(sys, outsiders[t])
				end		

                plt2 = plot(plt2, plt3, layout=(1,2))
                plot!(size=(675,250))
            else
                plot!(legend=:outertopright, size=size)
            end
        end

        return plt2
    end
end

function plot_msd_time_axis(sys::Project3SmallSystem, ψ::AvoidSetSpecification;
		is_dark_mode=DarkModeHandler.getdarkmode(),
		set_ratio=true,
		size=(400,350),
		title="",
		flip=false,
		kwargs...)

	dark_mode_plot(is_dark_mode;
		size,
		grid=false,
		title,
		titlefontsize=12,
		bottommargin=5Plots.mm)

	if flip
		xticks!(-0.4:0.2:0.4)
		ylabel!("""Time (s)
		""")
		xlabel!("""

		\$p\$ (m)""")
		ylims!(0, 1)
		xlims!(-0.6, 0.6)

		plot!(rectangle(0.3, 5, 0.3, 0), opacity=0.5, color=PASTEL_RED, label=false)
		plot!(rectangle(0.3, 5, -0.6, 0), opacity=0.5, color=PASTEL_RED, label=false)
	else
		yticks!(-0.4:0.2:0.4)
		xlabel!("""

		Time (s)""")
		ylabel!("\$p\$ (m)")
		xlims!(0, 1)
		ylims!(-0.6, 0.6)

		plot!(rectangle(5, 0.3, 0, 0.3), opacity=0.5, color=PASTEL_RED, label=false)
		plot!(rectangle(5, 0.3, 0, -0.6), opacity=0.5, color=PASTEL_RED, label=false)
	end

	if set_ratio
		set_aspect_ratio!()
	end
end

function plot_msd_traj!(sys::Project3SmallSystem, ψ::AvoidSetSpecification, τ;
		color=PASTEL_SKY_BLUE, alpha=1.0, lw=1, flip=false, kwargs...)
    times = collect(range(0, step=0.05, length=length(τ)))
	color = isfailure(ψ, τ) ? PASTEL_RED : color
	lw = isfailure(ψ, τ) ? 2lw : lw

	𝐩 = [step.s[1] for step in τ]
	if flip
		x = 𝐩
		y = times
	else
		x = times
		y = 𝐩
	end
	plot!(x, y;
		color,
		lw,
		alpha,
		label=false,
		kwargs...
	)
end

function plot_pendulum_state(sys::Project3MediumSystem, ψ;
                    is_dark_mode=DarkModeHandler.getdarkmode(),
					title="Inverted Pendulum",
					size=(680,350), kwargs...)

    dark_mode_plot(is_dark_mode; size, grid=false)
	plot!(rectangle(1.2-π/4, 2.4, -1.2, -1.2), opacity=0.5, color=PASTEL_RED, label=false)
	plot!(rectangle(1.2-π/4, 2.4, π/4, -1.2), opacity=0.5, color=PASTEL_RED, label=false)
	xlabel!("𝜃 (rad)")
	ylabel!("ω (rad/s)")
	title!(title)
	xlims!(-1.2, 1.2)
	ylims!(-1.2, 1.2)
	set_aspect_ratio!()
    return plot!()
end

plot_pendulum_solution!(sys::Project3MediumSystem, ψ, ℛ; kwargs...) = plot_pendulum_solution(sys, ψ, ℛ; hold=true, kwargs...)
function plot_pendulum_solution(sys::Project3MediumSystem, ψ, ℛ;
		τs=missing,
		hold=false,
		lw=1.5,
		linealpha=1,
		fillalpha=0.2,
		t=get_depth(sys))

	if !hold
		plot_pendulum_state(sys, ψ)
	end

	if !ismissing(τs)
		scatter!([τ[t].s[1] for τ in τs], [τ[t].s[2] for τ in τs];
			ms=1,
			color=PASTEL_SKY_BLUE,
			msc=PASTEL_SKY_BLUE,
			label=false)
	end

	plotset!(ℛ[t];
		lw,
		linealpha,
		fillalpha,
		label=false)

	xlims!(-1.2, 1.2)
	ylims!(-1.2, 1.2)

	return plot!()
end

Plots.plot(sys::Project3LargeSystem, ψ; kwargs...) = plot(sys.env.cw, ψ; kwargs...)
Plots.plot(sys::Project3LargeSystemOriginal, ψ; kwargs...) = plot(sys.env, ψ; kwargs...)
Plots.plot!(sys::Project3LargeSystems, ψ; kwargs...) = plot(sys, ψ; hold=true, kwargs...)
function Plots.plot(env::ContinuumWorld, ψ;
                    is_dark_mode=DarkModeHandler.getdarkmode(),
					hold=false,
					size=(680,350))
    dark_mode_plot(is_dark_mode; size, hold, grid=false)
	xmax = env.size[1]
	ymax = env.size[2]
	xlims!(0, xmax)
	ylims!(0, ymax)
	plot!(xticks=[0,xmax÷2,xmax], yticks=[0,ymax÷2,ymax], label=false)
	set_aspect_ratio!()

	goal = env.terminal_centers[2]
	fail = env.terminal_centers[1]
	rg = env.terminal_radii[2]
	rf = env.terminal_radii[1]

	plot!(circle(goal, rg), seriestype=:shape, color=PASTEL_GREEN, lc="transparent", label=false)
	plot!(circle(fail, rf), seriestype=:shape, color=PASTEL_RED, lc="transparent", label=false)
end

function plot_cw_trajectory!(τ;
		t=missing,
		t_multiplier=10,
		color=:black,
		lw=2,
		label=false,
		kwargs...)
	states = [step.s for step in τ]
    diffs = [states[i+1] - states[i] for i in 1:length(states)-1]
    traj_inds = findall([diff != [0, 0] for diff in diffs])
    traj_inds = [traj_inds; traj_inds[end]+1]
    xs = [s[1] for s in states[traj_inds]]
    ys = [s[2] for s in states[traj_inds]]

	points = hcat(xs, ys)

	# Calculate cumulative distances for parametrization
	distances = [0.0]
	for i in 2:length(xs)
	    dist = Euclidean()(points[i, :], points[i-1, :])
	    push!(distances, distances[end] + dist)
	end
	time = distances

	# Create cubic spline interpolations for x(t) and y(t)
	itp_x = interpolate_spline(time, xs, CardinalMonotonicInterpolation(0))
	itp_y = interpolate_spline(time, ys, CardinalMonotonicInterpolation(0))
	n = 1000
	t_smooth = LinRange(time[1], time[end], n)
	x_smooth = itp_x.(t_smooth)
	y_smooth = itp_y.(t_smooth)

	if ismissing(t)
		plot!(x_smooth, y_smooth; color, lw, label, kwargs...)
	else
		step_size = t_multiplier*(t_smooth[2] - t_smooth[1])
		n_steps = ceil(Int, t / step_size)
		n_steps = min(n_steps, length(t_smooth))
		plot!(x_smooth[1:n_steps], y_smooth[1:n_steps]; color, lw, label, kwargs...)
	end
end

function cw_success_and_failure(sys::Project3LargeSystems, ψ; d=20, n=200, seed=0)
	env1 = ContinuumWorld(Σ=0.2*I(2))
	env2 = ContinuumWorld(Σ=0.3*I(2))
	sensor = sys.sensor
	agent = sys.agent
	if sys.env isa ContinuumWorldSurrogate
		env1 = ContinuumWorldSurrogate(env1, sys.env.model)
		env2 = ContinuumWorldSurrogate(env2, sys.env.model)
	end
	cw1 = System(agent, env1, sensor)
	cw2 = System(agent, env2, sensor)
	ψ = LTLSpecification(ψ.formula.ψ) # Only obstacle portion of the specification

	Random.seed!(seed)
	success_τ = rollout(cw1; d)

	τs = [rollout(cw2; d) for _ in 1:n]
	failure_idx = findfirst(isfailure(ψ, τ) for τ in τs)
	isnothing(failure_idx) && @warn("No failures found.")
	failure_τ = τs[something(failure_idx, 1)]

	return success_τ, failure_τ
end

function cw_generate_trajectory(sys::Project3LargeSystems, ψ; d=20, n=200, seed=0)
	env = ContinuumWorld(Σ=0.2*I(2))
	sensor = sys.sensor
	agent = sys.agent
	if sys.env isa ContinuumWorldSurrogate
		env = ContinuumWorldSurrogate(env, sys.env.model)
	end
	cw = System(agent, env, sensor)
	Random.seed!(seed)
	τ = rollout(cw; d)
	return τ
end

function plotsamples!(::Project3LargeSystem, τs, t;
		sp=missing,
		is_dark_mode=DarkModeHandler.getdarkmode(),
		cmap)
	c = get(cmap, ((t-1) % length(cmap)) / (length(cmap) - 1))
	sc! = ismissing(sp) ? scatter! : (args...; kwargs...) -> scatter!(sp[2], args...; kwargs...)
	sc!([τ[t].s[1] for τ in τs], [τ[t].s[2] for τ in τs];
		ms=1,
		msw=0.1,
		color=c,
		msc=is_dark_mode ? :white : :black,
		label=false)
end

function plotoutsiders!(::Union{Project3SmallSystem,Project3MediumSystem,Project3LargeSystem}, outsiders_t;
		is_dark_mode=DarkModeHandler.getdarkmode(),
		sp=missing,
		ms=2,
		marker=:x)
	sc! = ismissing(sp) ? scatter! : (args...; kwargs...) -> scatter!(sp[2], args...; kwargs...)
	for s in outsiders_t
		sc!([s[1]], [s[2]];
			ms=ms,
			msw=0.3,
			color=:crimson,
			marker=marker,
			msc=is_dark_mode ? :white : :black,
			label=false)
	end
	return plot!()
end


function plotting_vertices(ℛ; ϵ=1e-7)
	V = LazySets.plot_vlist(ℛ, ϵ)
	push!(V, V[1])
	return V
end

compute_volume(ℛ) = sum(𝓇->LazySets.volume(VPolygon(plotting_vertices(𝓇))), ℛ)

plotset!(ℛ; kwargs...) = plotset(ℛ; hold=true, kwargs...)
function plotset(ℛ;
		hold=false,
		sp=missing,
		c="#2E6C8E",
		fillcolor=c,
		fill=true,
		fillalpha=0.2,
		label=false,
		kwargs...)
	V = plotting_vertices(ℛ)
	_plot = hold ? plot! : plot
	pl = ismissing(sp) ? _plot : (args...; kwargs...) -> _plot(sp[2], args...; kwargs...)
	pl(first.(V), last.(V);
		c=c,
		fillcolor=fillcolor,
		fill=fill,
		fillalpha=fillalpha,
		label=label,
		kwargs...)
end

function plot_cw_full_reachability(sys::Project3LargeSystem, ψ, τs, ℛ;
		is_dark_mode=DarkModeHandler.getdarkmode(),
		cmap,
		title="",
		issound=missing,
		include_samples=true)
	plot(sys, ψ)

	for t in 1:get_depth(sys)
		if issound[t]
			c = get(cmap, ((t-1) % length(cmap)) / (length(cmap) - 1))
		else
			c = PASTEL_RED
		end

		if include_samples
			scatter!([τ[t].s[1] for τ in τs], [τ[t].s[2] for τ in τs];
				ms=1,
				msw=0,
				color=c,
				msc=c,
				label=false)
		end

		plotset!(ℛ[t]; c)
	end

	c_outline = is_dark_mode ? :white : :black
	plot!([0,10], [0,0], color=c_outline, alpha=0.2, label=false, ls=:dash)
	plot!([10,10], [0,10], color=c_outline, alpha=0.2, label=false, ls=:dash)
	plot!([0,10], [10,10], color=c_outline, alpha=0.2, label=false, ls=:dash)
	plot!([0,0], [10,0], color=c_outline, alpha=0.2, label=false, ls=:dash)

	return plot!(title=title, titlefontsize=12, size=(350,350), xlims=(-0.5, 10.5), ylims=(-0.5, 10.5))
end

function precompute_soundness_and_outsiders(sys::Union{Project3SmallSystem,Project3MediumSystem,Project3LargeSystem}, ℛ::UnionSet, τs)
	ℛ = concretize.(fan_sets(ℛ))
	return precompute_soundness_and_outsiders(sys, ℛ, τs)
end

function precompute_soundness_and_outsiders(sys::Union{Project3SmallSystem,Project3MediumSystem,Project3LargeSystem}, ℛ::Union{UnionSetArray, Vector}, τs)
	d = get_depth(sys)
	issound = falses(d)
	outsiders = Dict()

	for t in 1:d
		ℛt = concretize(ℛ[t])
		sound = true
		outsiders[t] = []
		for τ in τs
			if vec(τ[t].s) ∉ ℛt
				sound = false
				push!(outsiders[t], τ[t].s)
			end
		end
		# issound[t] = all(τ->τ[t].s ∈ ℛt, τs)
		issound[t] = sound
	end

	return issound, outsiders
end

function plot_cw_reachability(sys::Project3LargeSystem, ψ, ℛ;
		is_dark_mode=DarkModeHandler.getdarkmode(),
		t=get_depth(sys),
		τs=missing,
		cmap=cgrad(:viridis),
		ℛmax,
		title="",
		issound=missing,
		outsiders=missing)

	plot(sys, ψ)

	has_unsound = false

	for tᵢ in 1:t
		c = get(cmap, ((tᵢ-1) % length(cmap)) / (length(cmap) - 1))

		ℛ_plot = bounded_set(ℛ[tᵢ], ℛmax)

		if issound[tᵢ]
			set_color = c
			set_line_alpha_past = 0.1
		else
			set_color = PASTEL_RED
			set_line_alpha_past = 0.5
			# @warn "Not sound (time = $tᵢ)!"
		end

		plotset!(ℛ_plot;
			lw=1.5,
			c=set_color,
			alpha=tᵢ < t ? set_line_alpha_past : 1,
			fillalpha=tᵢ < t ? 0.05 : 0.2,
			label=false)
		
		if tᵢ == t
			plotsamples!(sys, τs, tᵢ; cmap)
			if !isempty(outsiders[tᵢ])
				has_unsound = true # Only on the current t time.
				plotoutsiders!(sys, outsiders[tᵢ])
			end
		end
	end

	c_outline = is_dark_mode ? :white : :black
	plot!([0,10], [0,0], color=c_outline, alpha=0.2, label=false, ls=:dash)
	plot!([10,10], [0,10], color=c_outline, alpha=0.2, label=false, ls=:dash)
	plot!([0,10], [10,10], color=c_outline, alpha=0.2, label=false, ls=:dash)
	plot!([0,0], [10,0], color=c_outline, alpha=0.2, label=false, ls=:dash)

	plt_reach = plot!(title=title, titlefontsize=12, size=(650,400), xlims=(-0.5, 10.5), ylims=(-0.5, 10.5))

	if has_unsound
		# only show if points are outsiders...
		𝐱 = [τ[t].s[1] for τ in τs]
		𝐲 = [τ[t].s[2] for τ in τs]
		μx = mean(𝐱)
		σx = std(𝐱)
		μy = mean(𝐲)
		σy = std(𝐲)
		σ = max(σx, σy)
		offset = 3σ
		plot!(plt_reach,
			inset=bbox(0.21, 0.13, 0.33, 0.33, :bottom, :right),
			subplot=2
		)
		ℛt = concretize(ℛ[t])
		ℛ_plot = bounded_set(ℛt, ℛmax)

		p2 = plotset!(ℛ_plot;
			sp=plt_reach,
			lw=1.5,
			c=PASTEL_RED,
			alpha=1,
			fillalpha=0.2,
			label=false)

		plotoutsiders!(sys, outsiders[t]; sp=plt_reach, ms=4, marker=:star5)
		plotsamples!(sys, τs, t; sp=plt_reach, cmap)
		return plot!(p2[2],
			background_color_inside=is_dark_mode ? DARK_MODE_BACKGROUND : LIGHT_MODE_BACKGROUND,
			xlims=(μx - offset, μx + offset),
			ylims=(μy - offset, μy + offset),
			ratio=1,
			axis=[],
			title="Unsound",
			titlefontsize=10,
		)
	else
		return plt_reach
	end
end