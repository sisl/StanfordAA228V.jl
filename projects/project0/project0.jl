### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# ╔═╡ 173388ab-207a-42a6-b364-b2c1cb335f6b
# ╠═╡ show_logs = false
begin
	using Test
	using PlutoUI
	using Pkg
	Pkg.develop(path=joinpath("..", "..")) # "develop" the local AA228V package
	using AA228V
	using AA228V.Distributions
	using AA228V.Random
	using AA228V.Plots
	default(fontfamily="Computer Modern", framestyle=:box) # LaTeX-style plotting

	md"> **Package management**: _Hidden_ (click the \"eye\" icon to reveal)."
end

# ╔═╡ 60f72d30-ab80-11ef-3c20-270dbcdf0cc4
md"""
# Project 0: Falsification introduction
_A light-weight introduction to falsification._

**Task**: Simply count the number of failures for a 1d Gaussian environment.
"""

# ╔═╡ 17fa8557-9656-4347-9d44-213fd3b635a6
md"""
## System
The system is comprised of an `agent`, environment (`env`), and `sensor`.

⚠️ Note: **PLEASE DO NOT MODIFY**.
"""

# ╔═╡ 22feee3d-4627-4358-9937-3c780b7e8bcb
begin
	agent = NoAgent()
	env = SimpleGaussian()
	sensor = IdealSensor()
	sys = System(agent, env, sensor)
end

# ╔═╡ 45f7c3a5-5763-43db-aba8-41ef8db39a53
md"""
## Environment
Environment is a standard normal (Gaussian) distribution $\mathcal{N}(0, 1)$.
"""

# ╔═╡ 9c1daa96-76b2-4a6f-8d0e-f95d26168d2b
ps = Ps(env)

# ╔═╡ 370a15eb-df4b-493a-af77-00914b4616ea
md"""
## Specification $\psi$
The specification $\psi$ (written `\psi<TAB>` in code) indicates what the system should do:

$$\psi(s) = \square(s > -2)$$

i.e., "the system state $s$ should _always_ ($\square$) be above $-2$, anything else is a failure."

⚠️ Note: **PLEASE DO NOT MODIFY**.
"""

# ╔═╡ ab4c6807-5b4e-4688-b794-159e26a1599b
ψ = LTLSpecification(@formula □(s->s > -2));

# ╔═╡ 0cdadb29-9fcd-4a70-9937-c24f07ce4657
begin
	dark_mode = false

	if dark_mode
		plot(
			bg="transparent",
			background_color_inside="black",
			bglegend="black",
			fg="white",
			gridalpha=0.5,
		)
	else
		plot()
	end

	# Create a range of x values
	_X = range(-4, 4, length=1000)
	_Y = pdf.(ps, _X)
	
	# Plot the Gaussian density
	plot!(_X, _Y,
	     xlim=(-4, 4),
	     ylim=(0, 0.41),
	     linecolor=dark_mode ? "white" : "black",
		 fillcolor=dark_mode ? "darkgray" : "lightgray",
		 fill=true,
	     xlabel="state \$s\$",
	     ylabel="density \$p(s)\$",
	     size=(600, 300),
	     label=false)
	
	# Identify the indices where x <= -2
	idx = _X .<= ψ.formula.ϕ.c
	
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
	vline!([ψ.formula.ϕ.c], color="crimson", label="Failure threshold")
end

# ╔═╡ 86db41bf-c699-426c-a026-971b79dc0e2c
md"""
# **Task**: Count the number of failures

☑️ Fill in the following `num_failures` function.
"""

# ╔═╡ 798451be-5646-4b5e-b4d7-04d9fc9e6699
"""
    num_failures(sys, ψ; d, n)

A function that takes in a system `sys` and a specification `ψ` and returns the number of failures.

- `d` = rollout depth
- `n` = number of rollouts
"""
function num_failures(sys, ψ; d=100, n=1000)
    # TODO — WRITE YOUR CODE HERE. Remember to return the number of failures.
end

# ╔═╡ 873c99d8-ebd8-4ce3-92ca-6975c713fc8b
md"""
## Example usage of `num_failures`
"""

# ╔═╡ 2e2ec720-f9eb-4866-b3cc-7b9a66a7c698
md"""
Example usage with rollout depth `d=10` and `n=1000` number of rollouts.
"""

# ╔═╡ a6e52a4e-6e75-4ae0-9e3a-cc82f9ad6b2b
num_failures(sys, ψ; d=100, n=1000)

# ╔═╡ 00d4d678-a19d-4bba-b8f5-79d7e1466a63
md"""
## Useful interface functions
The following functions are provided by `AA228V.jl` that you may use.

**`rollout(sys::System; d)::Array`** — Run a single rollout of the system `sys` to a depth of `d`.
```julia
function rollout(sys::System; d)
    s = rand(Ps(sys.env))
    τ = []
    for t in 1:d
        o, a, s′ = step(sys, s)
        push!(τ, (; s, o, a))
        s = s′
    end
    return τ
end
```

**`isfailure(ψ, τ)::Bool`** — Using the specification `ψ`, check if the trajector `τ` led to a failure.
```julia
isfailure(ψ::Specification, τ) = !evaluate(ψ, τ)
```
"""

# ╔═╡ 2827a6f3-47b6-4e6f-b6ae-63271715d1f3
md"""
# Tests
The tests below test your `num_failures` function to see if it works properly.

This will automatically run anytime the `num_failures` function is changed and saved (due to Pluto having dependent cells).

⚠️ Note: **PLEASE DO NOT MODIFY**.
"""

# ╔═╡ 18f9700c-08cd-496e-ac8c-42f01f65a575
global SEED = sum(Int.(collect("AA228V")));

# ╔═╡ 83884eb4-6718-455c-b731-342471325326
function test_project0(n_failures::Function; d=100, n=1000, seed=SEED)
	Random.seed!(seed) # For determinism
    return n_failures(sys, ψ; d, n)
end

# ╔═╡ 4a91853f-9685-47f3-998a-8e0cfce688f8
md"""
## Running tests
"""

# ╔═╡ b6f15d9c-33b8-40e3-be57-d91eda1c9753
test1_output = test_project0(num_failures; d=100, n=1000, seed=SEED)

# ╔═╡ 3314f402-10cc-434c-acbc-d38e59e4b846
test2_output = test_project0(num_failures; d=100, n=5000, seed=SEED)

# ╔═╡ ba6c082b-6e62-42fc-a85c-c8b7efc89b88
md"""
# Backend
"""

# ╔═╡ c151fc99-af4c-46ae-b55e-f50ba21f1f1c
begin
	function hint(text)
		return Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))
	end

	function almost()
		text=md"Please modify the `num_failures` function (currently returning `nothing`, which is the default)."
		return Markdown.MD(Markdown.Admonition("warning", "Warning!", [text]))
	end

	function keep_working()
		text = md"The answers are not quite right."
		return Markdown.MD(Markdown.Admonition("danger", "Keep working on it!", [text]))
	end

	function correct()
		text = md"""
		All tests have passed, you're done with Project 0!
		
		Please submit `project0.jl` (this file) to Gradescope.
		"""
		return Markdown.MD(Markdown.Admonition("correct", "Tests passed!", [text]))
	end

	md"> Academic markdown helper functions located here."
end

# ╔═╡ 6302729f-b34a-4a18-921b-d194fe834208
begin
	test1_passed::Bool = test1_output == 19
	test2_passed::Bool = test2_output == 110

	if test1_passed && test2_passed
		correct()
	elseif isnothing(test1_output) && isnothing(test1_output)
		almost()
	else
		keep_working()
	end
end

# ╔═╡ ef084fea-bf4d-48d9-9c84-8cc1dd98f2d7
TableOfContents()

# ╔═╡ Cell order:
# ╟─60f72d30-ab80-11ef-3c20-270dbcdf0cc4
# ╟─17fa8557-9656-4347-9d44-213fd3b635a6
# ╠═22feee3d-4627-4358-9937-3c780b7e8bcb
# ╟─45f7c3a5-5763-43db-aba8-41ef8db39a53
# ╠═9c1daa96-76b2-4a6f-8d0e-f95d26168d2b
# ╟─370a15eb-df4b-493a-af77-00914b4616ea
# ╠═ab4c6807-5b4e-4688-b794-159e26a1599b
# ╟─0cdadb29-9fcd-4a70-9937-c24f07ce4657
# ╟─86db41bf-c699-426c-a026-971b79dc0e2c
# ╠═798451be-5646-4b5e-b4d7-04d9fc9e6699
# ╟─873c99d8-ebd8-4ce3-92ca-6975c713fc8b
# ╟─2e2ec720-f9eb-4866-b3cc-7b9a66a7c698
# ╠═a6e52a4e-6e75-4ae0-9e3a-cc82f9ad6b2b
# ╟─00d4d678-a19d-4bba-b8f5-79d7e1466a63
# ╟─2827a6f3-47b6-4e6f-b6ae-63271715d1f3
# ╠═18f9700c-08cd-496e-ac8c-42f01f65a575
# ╠═83884eb4-6718-455c-b731-342471325326
# ╟─4a91853f-9685-47f3-998a-8e0cfce688f8
# ╠═b6f15d9c-33b8-40e3-be57-d91eda1c9753
# ╠═3314f402-10cc-434c-acbc-d38e59e4b846
# ╟─6302729f-b34a-4a18-921b-d194fe834208
# ╟─ba6c082b-6e62-42fc-a85c-c8b7efc89b88
# ╟─173388ab-207a-42a6-b364-b2c1cb335f6b
# ╟─c151fc99-af4c-46ae-b55e-f50ba21f1f1c
# ╠═ef084fea-bf4d-48d9-9c84-8cc1dd98f2d7
