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
global DARK_MODE_BACKGROUND = "#1A1A1A"

########################################
## SmallSystem: Projects 1 & 2
##     Simple Gaussian 
########################################

function Plots.plot(sys::Project1SmallSystem, ψ, τ=missing;
					is_dark_mode=DarkModeHandler.getdarkmode(),
                    max_points=500, kwargs...)
	ps = Ps(sys.env)

	plot(
		bg="transparent",
		background_color_inside=is_dark_mode ? DARK_MODE_BACKGROUND : "white",
		bglegend=is_dark_mode ? DARK_MODE_BACKGROUND : "white",
		fg=is_dark_mode ? "white" : "black",
		gridalpha=is_dark_mode ? 0.5 : 0.1,
	)

	# Create a range of x values
	_X = range(-4, 4, length=1000)
	_Y = pdf.(ps, _X)

	# Plot the Gaussian density
	plot!(_X, _Y,
	     xlim=(-4, 4),
	     ylim=(-0.001, 0.41),
	     linecolor=is_dark_mode ? "white" : "black",
		 fillcolor=is_dark_mode ? "darkgray" : "lightgray",
		 fill=true,
	     xlabel="state \$s\$",
	     ylabel="density \$p(s)\$",
	     size=(600, 300),
	     label=false)

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
	vline!([c];
		   color="crimson", legend=:topleft, label="Failure threshold")

	if !ismissing(τ)
		count_plotted_succeses = 0
		count_plotted_failures = 0
		function plot_point!(τᵢ)
			if isfailure(ψ, τᵢ) && count_plotted_failures == 0
				label = "Failure state"
				count_plotted_failures += 1
			elseif !isfailure(ψ, τᵢ) && count_plotted_succeses == 0
				label = "Succes state"
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

	plot(
		bg="transparent",
		background_color_inside=is_dark_mode ? DARK_MODE_BACKGROUND : "white",
		bglegend=is_dark_mode ? DARK_MODE_BACKGROUND : "white",
		fg=is_dark_mode ? "white" : "black",
		gridalpha=is_dark_mode ? 0.5 : 0.1,
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

	# Extract the x and y values for the region to fill
	idx = _X .≤ ψ.formula.ϕ.c
	x_fill = _X[idx]
	y_fill = _Y[idx]

	# Create the coordinates for the filled polygon
	# Start with the x and y values where x <= -2
	# Then add the same x values in reverse with y = 0 to close the polygon
	polygon_x = vcat(x_fill, reverse(x_fill))
	polygon_y = vcat(y_fill, zeros(length(y_fill)))

	Pc = cdf(ps, ψ.formula.ϕ.c)

	# Add the filled area to the plot
	plot!(polygon_x, polygon_y,
	      fill=true,
	      fillcolor="crimson",
	      linecolor="transparent", # No border for the filled area
		  lw=0,
		  alpha=0.5,
	      label="\$P(s < $c) \\ ≈ \\ $(round(Pc; digits=4)) \$",
		  legend=:topleft)

	plot!([c, c], [0, Pc];
		   ls=:dash, color=dash_color, label=false)
	plot!([-4, c], fill(Pc, 2);
		   ls=:dash, color=dash_color, label=false)

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
	plot(
		size=size,
		grid=false,
		bg="transparent",
		background_color_inside=is_dark_mode ? DARK_MODE_BACKGROUND : "white",
		fg=is_dark_mode ? "white" : "black",
	)

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
	plot(;
		grid=false,
		axis=false,
		bg="transparent",
		background_color_inside="transparent",
		fgcolor=is_dark_mode ? "white" : "black",
		title=title,
		kwargs...
	)
	l = 3 # Pendulum length
	buffer = 1.05 # Axis limit buffer
	lt = 1.1l # Failure threshold length

	xlims!(-l*buffer, l*buffer)
	ylims!(-l*buffer, l*buffer)
	set_aspect_ratio!()

	# Background circle
	plot!(circle([0,0], l), seriestype=:shape, color="#b9e2d5", lc="transparent", label=false)

	# Failure regions
	plot!(halfcircle([0,0], l, c), seriestype=:shape, color="#fbdfdc", lc="transparent", label=false)

	plot!(halfcircle([0,0], l, -c), seriestype=:shape, color="#fbdfdc", lc="transparent", label=false)

	# Outline
	plot!(circle([0,0], l), seriestype=:shape, color="transparent", lc="transparent", label=false)

	# Failure thresholds
	plot!([0, lt*sin(c)], [0, lt*cos(c)], color="#F5615C", ls=:dash, lw=2, label=false)

	plot!([0, lt*sin(-c)], [0, lt*cos(-c)], color="#F5615C", ls=:dash, lw=2, label=false)

	# Pendulum
	topx = l * sind(θ)
	topy = l * cosd(θ)

	pend_color = θ < -rad2deg(c) || θ > rad2deg(c) ? "#F5615C" : "black"
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
                    flw=2, fα=1, sα=0.25, slw=1, size=(680,350), title="", hold=false, kwargs...)
    _plot = hold ? plot! : plot
    _plot(;
        size,
        grid=false,
        bg="transparent",
        background_color_inside=is_dark_mode ? DARK_MODE_BACKGROUND : "white",
        fg=is_dark_mode ? "white" : DARK_MODE_BACKGROUND,
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
                marker = (shape, 1, "black")
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
            plot(px, py;
                ribbon=pvar,
                fillcolor=fail_color,
                fillalpha=0.1,
                color=fail_color,
                lw=2,
                label=false,
                size=(680,350),
                grid=false,
                bg="transparent",
                background_color_inside=is_dark_mode ? DARK_MODE_BACKGROUND : "white",
                fg=is_dark_mode ? "white" : "black",
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
