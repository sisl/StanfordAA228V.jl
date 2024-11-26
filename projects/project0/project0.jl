### A Pluto.jl notebook ###
# v0.20.3

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

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

If you encounter issues, [please ask us on Ed](https://edstem.org/us/courses/69226/discussion).
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
The environment is a standard normal (Gaussian) distribution $\mathcal{N}(0, 1)$.
"""

# ╔═╡ 9c1daa96-76b2-4a6f-8d0e-f95d26168d2b
ps = Ps(env)

# ╔═╡ ab4c6807-5b4e-4688-b794-159e26a1599b
ψ = LTLSpecification(@formula □(s->s > -2));

# ╔═╡ 370a15eb-df4b-493a-af77-00914b4616ea
Markdown.parse("""
## Specification \$\\psi\$
The specification \$\\psi\$ (written `\\psi<TAB>` in code) indicates what the system should do:

\$\$\\psi(s) = \\square(s > $(ψ.formula.ϕ.c))\$\$

i.e., "the system state \$s\$ should _always_ (\$\\square\$) be above \$$(ψ.formula.ϕ.c)\$, anything else is a failure."

⚠️ Note: **PLEASE DO NOT MODIFY**.
""")

# ╔═╡ 166bd412-d433-4dc9-b874-7359108c0a8b
Markdown.parse("""
A failure is unlikely given that the probability of failure is:

\$\$p(s > -2) \\approx $(round(cdf(ps, ψ.formula.ϕ.c), sigdigits=4))\$\$
""")

# ╔═╡ 86db41bf-c699-426c-a026-971b79dc0e2c
html"""
<h1><b>👩‍💻 Task</b>: Count the number of failures</h1>
<p>Please fill in the following <code>num_failures</code> function.</p>
<p><span style='color:#B1040E'><b><code>&lt;START CODE&gt;</code></b></span></p>
<!-- START_CODE -->
"""

# ╔═╡ 798451be-5646-4b5e-b4d7-04d9fc9e6699
"""
    num_failures(sys, ψ; d, n)

A function that takes in a system `sys` and a specification `ψ` and returns the number of failures.

- `d` = rollout depth
- `n` = number of rollouts
"""
function num_failures(sys, ψ; d=100, n=1000)
    # TODO: WRITE YOUR CODE HERE. Remember to return the number of failures.
end

# ╔═╡ 651313a4-2766-49dd-8737-475ed80079e2
html"""
<!-- END_CODE -->
<p><span style='color:#B1040E'><b><code>&lt;END CODE&gt;</code></b></span></p>
<hr/>
"""

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
# 📊 Tests 
The tests below run your `num_failures` function to see if it works properly.

This will automatically run anytime the `num_failures` function is changed and saved (due to Pluto having dependent cells).

⚠️ Note: **PLEASE DO NOT MODIFY**.
"""

# ╔═╡ 4a91853f-9685-47f3-998a-8e0cfce688f8
md"""
## Running tests
Run two tests, controlling the RNG seed for deterministic outputs.
"""

# ╔═╡ 2ff6bb9c-5282-4ba1-b62e-a9fd0fe1969c
md"""
### Test 1
"""

# ╔═╡ 089581ec-8aff-4c56-9a65-26d394d5eec3
md"""
### Test 2
"""

# ╔═╡ cee165f0-049f-4ea3-8f19-04e66947a397
html"""
<h3>Check tests</h3>
<p>If the following test indicator is <span style='color:#759466'><b>green</b></span>, you can submit <code>project0.jl</code> (this file) to Gradescope.</p>
"""

# ╔═╡ ba6c082b-6e62-42fc-a85c-c8b7efc89b88
md"""
# Backend
_You can ignore this._
"""

# ╔═╡ c151fc99-af4c-46ae-b55e-f50ba21f1f1c
begin
	function hint(text)
		return Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))
	end

	function almost()
		text=md"""
		Please modify the `num_failures` function (currently returning `nothing`, which is the default).

		(Please only submit when this is **green**.)
		"""
		return Markdown.MD(Markdown.Admonition("warning", "Warning!", [text]))
	end

	function keep_working()
		text = md"""
		The answers are not quite right.
		
		(Please only submit when this is **green**.)
		"""
		return Markdown.MD(Markdown.Admonition("danger", "Keep working on it!", [text]))
	end

	function correct()
		text = md"""
		All tests have passed, you're done with Project 0!
		
		Please submit `project0.jl` (this file) to Gradescope.
		"""
		return Markdown.MD(Markdown.Admonition("correct", "Tests passed!", [text]))
	end

	global SEED = sum(Int.(collect("AA228V"))) # Cheeky seed value :)

	DarkModeIndicator() = PlutoUI.HypertextLiteral.@htl("""
		<span>
		<script>
			const span = currentScript.parentElement
			span.value = window.matchMedia('(prefers-color-scheme: dark)').matches
		</script>
		</span>
	""")

	md"> **Helper functions and variables**."
end

# ╔═╡ 83884eb4-6718-455c-b731-342471325326
function run_project0_test(n_failures::Function; d=100, n=1000, seed=SEED)
	Random.seed!(seed) # For determinism
    return n_failures(sys, ψ; d, n)
end

# ╔═╡ b6f15d9c-33b8-40e3-be57-d91eda1c9753
begin
	test1_n = 1000
	test1_output = run_project0_test(num_failures; d=100, n=test1_n, seed=SEED)
end

# ╔═╡ 522bb285-bc06-4c92-82ee-c0d0f68b184c
if isa(test1_output, Number)
	Markdown.parse("""
	The frequentist failure probability estimate for test 1 would be:
	
	\$\$\\hat{p}_{\\rm failure}^{({\\rm test}_1)} = \\frac{$(test1_output)}{$test1_n} =  $(test1_output/test1_n)\$\$
	""")
else
	md"*Update `num_failures` to get an estimated failure probability for test 1.*"
end

# ╔═╡ 3314f402-10cc-434c-acbc-d38e59e4b846
begin
	test2_n = 5000
	test2_output = run_project0_test(num_failures; d=100, n=test2_n, seed=SEED)
end

# ╔═╡ d72be566-6ad7-4817-8590-a504a699a4da
if isa(test2_output, Number)
	Markdown.parse("""
	The frequentist failure probability estimate for test 2 would be:
	
	\$\$\\hat{p}_{\\rm failure}^{({\\rm test}_2)} = \\frac{$(test2_output)}{$test2_n} =  $(test2_output/test2_n)\$\$
	""")
else
	md"*Update `num_failures` to get an estimated failure probability for test 2.*"
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

# ╔═╡ a6931d1e-08ad-4592-a54c-fd76cdc51294
@bind dark_mode DarkModeIndicator()

# ╔═╡ 0cdadb29-9fcd-4a70-9937-c24f07ce4657
begin
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
# ╟─166bd412-d433-4dc9-b874-7359108c0a8b
# ╟─86db41bf-c699-426c-a026-971b79dc0e2c
# ╠═798451be-5646-4b5e-b4d7-04d9fc9e6699
# ╟─651313a4-2766-49dd-8737-475ed80079e2
# ╟─873c99d8-ebd8-4ce3-92ca-6975c713fc8b
# ╟─2e2ec720-f9eb-4866-b3cc-7b9a66a7c698
# ╠═a6e52a4e-6e75-4ae0-9e3a-cc82f9ad6b2b
# ╟─00d4d678-a19d-4bba-b8f5-79d7e1466a63
# ╟─2827a6f3-47b6-4e6f-b6ae-63271715d1f3
# ╠═83884eb4-6718-455c-b731-342471325326
# ╟─4a91853f-9685-47f3-998a-8e0cfce688f8
# ╟─2ff6bb9c-5282-4ba1-b62e-a9fd0fe1969c
# ╠═b6f15d9c-33b8-40e3-be57-d91eda1c9753
# ╟─522bb285-bc06-4c92-82ee-c0d0f68b184c
# ╟─089581ec-8aff-4c56-9a65-26d394d5eec3
# ╠═3314f402-10cc-434c-acbc-d38e59e4b846
# ╟─d72be566-6ad7-4817-8590-a504a699a4da
# ╟─cee165f0-049f-4ea3-8f19-04e66947a397
# ╟─6302729f-b34a-4a18-921b-d194fe834208
# ╟─ba6c082b-6e62-42fc-a85c-c8b7efc89b88
# ╟─173388ab-207a-42a6-b364-b2c1cb335f6b
# ╟─c151fc99-af4c-46ae-b55e-f50ba21f1f1c
# ╠═a6931d1e-08ad-4592-a54c-fd76cdc51294
# ╠═ef084fea-bf4d-48d9-9c84-8cc1dd98f2d7
