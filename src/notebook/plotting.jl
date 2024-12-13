

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
