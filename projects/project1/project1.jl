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
	using AA228V.ForwardDiff
	using AA228V.Optim
	using AA228V.Parameters
	using AA228V.BSON
	using AA228V.GridInterpolations
	using LinearAlgebra

	default(fontfamily="Computer Modern", framestyle=:box) # LaTeX-style plotting

	md"> **Package management**: _Hidden_ (click the \"eye\" icon to reveal)."
end

# ╔═╡ 60f72d30-ab80-11ef-3c20-270dbcdf0cc4
md"""
# Project 1: Finding the most-likely failure

**Task**: Efficiently find likely failures using $n$ total function calls to the system `step` function.
- **Small system**: 1D Gaussian $\mathcal{N}(0,1)$. With $n=100$ `step` calls.
- **Medium system**: Swinging inverted pendulum. With $n=1{,}000$ `step` calls.
- **Large system**: Aircraft collision avoidance system (CAS). With $n=10{,}000$ `step` calls.

Your job is to write the following function that returns the failure trajectory `τ` (i.e., a `Vector` of $(s,a,o,x)$ tuples) with the highest likelihood you found:
```julia
most_likely_failure(sys, ψ; d, m)::Vector
```

If you encounter issues, [please ask us on Ed](https://edstem.org/us/courses/69226/discussion).
"""

# ╔═╡ fd8c851a-3a42-41c5-b0fd-a12085543c9b
md"""
# 1️⃣ **Small**: 1D Gaussian
The small system is a simple 1D Gaussian system.
- There are no dynamics (rollout depth $d=1$).
- There are no disturbances.
- The (initial and only) state $s$ is sampled from $\mathcal{N}(0,1)$.
"""

# ╔═╡ 17fa8557-9656-4347-9d44-213fd3b635a6
Markdown.parse("""
## Small system
The system is comprised of an `agent`, environment (`env`), and `sensor`.
""")

# ╔═╡ 22feee3d-4627-4358-9937-3c780b7e8bcb
sys_small = System(NoAgent(), SimpleGaussian(), IdealSensor());

# ╔═╡ 6f3e24de-094c-49dc-b892-6721b3cc54ed
SmallSystem = typeof(sys_small) # Type used for multiple dispatch

# ╔═╡ 45f7c3a5-5763-43db-aba8-41ef8db39a53
md"""
## Small environment
The environment is a standard normal (Gaussian) distribution $\mathcal{N}(0, 1)$.
"""

# ╔═╡ 9c1daa96-76b2-4a6f-8d0e-f95d26168d2b
ps_small = Ps(sys_small.env)

# ╔═╡ ab4c6807-5b4e-4688-b794-159e26a1599b
ψ_small = LTLSpecification(@formula □(s->s > -2));

# ╔═╡ 370a15eb-df4b-493a-af77-00914b4616ea
Markdown.parse("""
## Small specification \$\\psi\$
The specification \$\\psi\$ (written `\\psi<TAB>` in code) indicates what the system should do:

\$\$\\psi(\\tau) = \\square(s > $(ψ_small.formula.ϕ.c))\$\$

i.e., "the state \$s\$ in the trajectory \$\\tau\$ should _always_ (\$\\square\$) be greater than \$$(ψ_small.formula.ϕ.c)\$, anything else is a failure."
""")

# ╔═╡ 166bd412-d433-4dc9-b874-7359108c0a8b
Markdown.parse("""
A failure is unlikely given that the probability of failure is:

\$\$p(s > $(ψ_small.formula.ϕ.c)) \\approx $(round(cdf(ps_small, ψ_small.formula.ϕ.c), sigdigits=4))\$\$
""")

# ╔═╡ 9132a200-f63b-444b-9830-b03cf075021b
md"""
## Baseline
The following function is a baseline random falsification algorithm that returns the trajectory that led to the most-likely failure.

**Your algorithm should do better than the random baseline.**
"""

# ╔═╡ c2ae204e-dbcc-453a-81f5-791ba4be39db
@tracked function most_likely_failure_baseline(sys, ψ; d=1, m=100)
	pτ = NominalTrajectoryDistribution(sys, d)         # Trajectory distribution
	τs = [rollout(sys, pτ; d) for _ in 1:m]            # Rollout with pτ, n*d steps
	τs_failures = filter(τ->isfailure(ψ, τ), τs)       # Filter to get failure trajs
	τ_most_likely = argmax(τ->pdf(pτ, τ), τs_failures) # Get most-likely failure traj
	return τ_most_likely
end

# ╔═╡ e73635cc-2b1e-4162-8760-b62184e70b6d
md"""
### Example usage of small baseline
Example usage with default rollout depth of `d=1` and `n=100` number of rollouts.

> **Note**: In Pluto, to put multiple lines of code in one cell, wrap in a `begin` `end` block.
"""

# ╔═╡ 7fe03702-25e5-473a-a92b-3b77eb753bc3
begin
	Random.seed!(4)
	τ_baseline_small = most_likely_failure_baseline(sys_small, ψ_small)
	pτ_small = NominalTrajectoryDistribution(sys_small)
	ℓτ_small = pdf(pτ_small, τ_baseline_small)
end;

# ╔═╡ 73da2a56-8991-4484-bcde-7d397214e552
Markdown.parse("""
### Baseline results (small)

\$\$\\begin{align}
\\ell_\\text{baseline} &= $(round(ℓτ_small, sigdigits=5))\\tag{most-likely failure likelihood} \\\\
n_\\text{steps} &= $(step_counter.count) \\tag{number of \\texttt{step} calls}
\\end{align}\$\$
""")

# ╔═╡ 92f20cc7-8bc0-4aea-8c70-b0f759748fbf
html"""
<h2><b>1. Task (Small)</b>: Most-likely failure</h2>
<p>Please fill in the following <code>most_likely_failure</code> function.</p>
<ul>
	<li><b>Note</b>: You have a maximum of <code>n=100</code> total calls to <code>step</code>.</li>
</ul>
<p><div class='container'><div class='line'></div><span class='text' style='color:#B1040E'><b><code>&lt;START CODE&gt;</code></b></span><div class='line'></div></div></p>
<p/>
<!-- START_CODE -->
"""

# ╔═╡ f6589984-e24d-4aee-b7e7-db159ae7fea6
md"""
	most_likely_failure(sys::SimpleGaussian, ψ; d, m)::Vector

A function that takes in a system `sys` (1D Gaussian for the _small_ setting) and a specification `ψ` and **returns the trajectory that led to the most-likely failure**.

- `d` = rollout depth (leave at `d=1` for the `SmallSystem`)
- `m` = number of rollouts

**Note**: `ψ` is written as `\psi<TAB>`
"""

# ╔═╡ fc2d34da-258c-4460-a0a4-c70b072f91ca
@tracked function most_likely_failure(sys::SmallSystem, ψ; d=1, m=100)
	# TODO: WRITE YOUR CODE HERE
end

# ╔═╡ c494bb97-14ef-408c-9de1-ecabe221eea6
html"""
<!-- END_CODE -->
<p><div class='container'><div class='line'></div><span class='text' style='color:#B1040E'><b><code>&lt;END CODE&gt;</code></b></span><div class='line'></div></div></p>
"""

# ╔═╡ ec776b30-6a30-4643-a22c-e071a365d50b
md"""
## Hints
Expand the sections below for some helpful hints.
"""

# ╔═╡ 8c78529c-1e00-472c-bb76-d984b37235ab
md"""
# 2️⃣ **Medium**: Inverted Pendulum
The medium system is a swinging inverted pendulum.
- It uses a proportional controller to keep it upright.
- The state is comprised of the angle $\theta$ and angular velocity $\omega$: $s = [\theta, \omega]$
- Actions are left/right adjustments in the range $[-2, 2]$
- Disturbances $\mathbf{x}$ are treated as addative noise: $\mathbf{x} \sim \mathcal{N}(\mathbf{0}, 0.1^2I)$
"""

# ╔═╡ daada216-11d4-4f8b-807c-d347130a3928
LocalResource(joinpath(@__DIR__, "..", "..", "media", "inverted_pendulum.svg"))

# ╔═╡ d18c2105-c2af-4dda-8388-617aa816a567
Markdown.parse("""
## Medium system
An inverted pendulum comprised of a `ProportionalController` with an `AdditiveNoiseSensor`.
""")

# ╔═╡ 77637b5e-e3ce-4ecd-90fc-95611af18002
sys_medium = System(
	ProportionalController([-15.0, -8.0]),
	InvertedPendulum(),
	AdditiveNoiseSensor(MvNormal(zeros(2), 0.1^2*I))
);

# ╔═╡ c4c0328d-8cb3-41d5-9740-0197cbf760c2
MediumSystem = typeof(sys_medium) # Type used for multiple dispatch

# ╔═╡ b1e9bd40-a401-4630-9a1f-d61b276e72f7
md"""
## Medium specification $\psi$
The inverted pendulum specification $\psi$ indicates what the system should do:

$$\psi(\tau) = \square\big(|\theta| < \pi/4\big)$$

i.e., "the absolute value of the pendulum angle $\theta$ (first element of the state $s$) in the trajectory $\tau$ should _always_ ($\square$) be less than $\pi/4$, anything else is a failure."
"""

# ╔═╡ fe272c1b-421c-49de-a513-80c7bcefdd9b
ψ_medium = LTLSpecification(@formula □(s -> abs(s[1]) < π / 4));

# ╔═╡ a16cf110-4afa-4792-9d3f-f13b24349886
md"""
## Medium example rollouts
Example rollouts of the pendulum system and their plot below.
"""

# ╔═╡ 8b82eb8d-f6fe-4b73-8617-8c75dd65b769
begin
	Random.seed!(4)
	pτ_medium_ex = NominalTrajectoryDistribution(sys_medium, 100)
	τs_rollout_medium = [rollout(sys_medium, pτ_medium_ex; d=100) for i in 1:1000] 
end;

# ╔═╡ 29b0823b-c76e-43a1-b7e6-d5b809082d65
[pdf(pτ_medium_ex, τ) for τ in τs_rollout_medium]

# ╔═╡ bdb27ba8-782c-467c-818d-f68c7790e845
md"""
## Baseline: Medium
Example usage with rollout depth of `d=100` and `m=1000` number of rollouts.
"""

# ╔═╡ 3d00dc65-4c48-4988-9bb9-4cd3af6b9c5b
begin
	Random.seed!(4)
	τ_base_medium = most_likely_failure_baseline(sys_medium, ψ_medium; d=100, m=1000)
	pτ_medium = NominalTrajectoryDistribution(sys_medium, 100)
	ℓτ_medium = pdf(pτ_medium, τ_base_medium)
	n_steps_medium = step_counter.count
end;

# ╔═╡ 7ef66a50-6acc-474f-b406-7b27a7b18510
Markdown.parse("""
### Baseline results (medium)

\$\$\\begin{align}
\\ell_\\text{baseline} &= $(round(ℓτ_medium, sigdigits=3))\\tag{most-likely failure likelihood} \\\\
n_\\text{steps} &= $(n_steps_medium) \\tag{number of \\texttt{step} calls \$d\\times n\$}
\\end{align}\$\$
""")

# ╔═╡ 1da9695f-b7fc-46eb-9ef9-12160246018d
md"""
## **2. Task (Medium)**: Most-likely failure
Please fill in the following `most_likely_failure` function.
- **Note**: You have a maximum of $n = d\times m = 1{,}000$ total calls to `step`.
    - For example $d=100$ and $m=10$
"""

# ╔═╡ 0606d827-9c70-4a79-afa7-14fb6b806546
html"""
<div class='container'><div class='line'></div><span class='text' style='color:#B1040E'><b><code>&lt;START CODE&gt;</code></b></span><div class='line'></div></div>
<p> </p>
<!-- START_CODE -->
"""

# ╔═╡ 9657f5ff-f21c-43c5-838d-402a2a723d5e
md"""
	most_likely_failure(sys::SimpleGaussian, ψ; d, m)::Vector

A function that takes in a system `sys` (inverted pendulum for the _medium_ setting) and a specification `ψ` and **returns the trajectory that led to the most-likely failure**.

- `d` = rollout depth
- `m` = number of rollouts

**Note**: `ψ` is written as `\psi<TAB>`
"""

# ╔═╡ cb7b9b9f-59da-4851-ab13-c451c26117df
@tracked function most_likely_failure(sys::MediumSystem, ψ; d=100, m=10)
	# TODO: WRITE YOUR CODE HERE
end

# ╔═╡ 759534ca-b40b-4824-b7ec-3a5c06cbd23e
html"""
<!-- END_CODE -->
<p><div class='container'><div class='line'></div><span class='text' style='color:#B1040E'><b><code>&lt;END CODE&gt;</code></b></span><div class='line'></div></div></p>
"""

# ╔═╡ 4943ca08-157c-40e1-acfd-bd9326082f56
md"""
## Hints
Useful tips to watch out for.
"""

# ╔═╡ 7d054465-9f80-4dfb-9b5f-76c3977de7cd
Markdown.parse("""
## Large system
An aircraft collision avoidance system that uses an interpolated lookup-table policy.
""")

# ╔═╡ 1ec68a39-8de9-4fd3-be8a-26cf7706d1d6
begin
	grid, Q = load_cas_policy(joinpath(@__DIR__, "cas_policy.bson"))

	cas_agent = InterpAgent(grid, Q)
	cas_env = CollisionAvoidance(Ds=Normal(0, 1.5))
	cas_sensor = IdealSensor()
	sys_large = System(cas_agent, cas_env, cas_sensor)

	LargeSystem = typeof(sys_large) # Type used for multiple dispatch
end

# ╔═╡ be426908-3fee-4ecd-b054-2497ce9a2e50
md"""
## Large specification $\psi$
The collision avoidance system specification $\psi$ indicates what the system should do:

$$\psi(\tau) = \square_{[41]}\big(|h| > 50\big)$$

i.e., "the absolute valued relative altitude $h$ (first element of the state $s$) in the trajectory $\tau$ should _always_ ($\square$) be greater than $50$ meters at the end of the encounter ($t=41$), anything else is a failure."
"""

# ╔═╡ 258e14c4-9a2d-4515-9a8f-8cd96f31a6ff
ψ_large = LTLSpecification(@formula □(41:41, s->abs(s[1]) > 50));

# ╔═╡ 1a097a88-e4f0-4a8d-a5d6-2e3858ee417c
begin
	Random.seed!(4)
	pτ_large_ex = NominalTrajectoryDistribution(sys_large, 41)
	τs_rollout_large = [rollout(sys_large, pτ_large_ex; d=41) for i in 1:10000]
end;

# ╔═╡ a4e0000b-4b4a-4262-bf0a-85509c4ee47e
md"""
## Baseline: Large
"""

# ╔═╡ b5d02715-b7c9-4bf2-a284-42da40a70a68
begin
	Random.seed!(4)
	τ_base_large = most_likely_failure_baseline(sys_large, ψ_large; d=41, m=10000)
	pτ_large = NominalTrajectoryDistribution(sys_large, 41)
	ℓτ_large = pdf(pτ_large, τ_base_large)
end;

# ╔═╡ 204feed7-cde8-40a8-b6b5-051a1c768fd9
Markdown.parse("""
### Baseline results (large)

\$\$\\begin{align}
\\ell_\\text{baseline} &= $(round(ℓτ_large, sigdigits=3))\\tag{most-likely failure likelihood} \\\\
n_\\text{steps} &= $(step_counter.count) \\tag{number of \\texttt{step} calls \$d\\times n\$}
\\end{align}\$\$
""")

# ╔═╡ 23fd490a-74d2-44b4-8a12-ea1460d95f85
md"""
## **3. Task (Large)**: Most-likely failure
Please fill in the following `most_likely_failure` function.
- **Note**: You have a maximum of $n = d\times m = 1{,}025{,}000$ total calls to `step`.
    - For $d=41$ and $m=25{,}000$
"""

# ╔═╡ 18a70925-3c2a-4317-8bbc-c2a096ec56d0
html"""
<!-- END_CODE -->
<p><div class='container'><div class='line'></div><span class='text' style='color:#B1040E'><b><code>&lt;END CODE&gt;</code></b></span><div class='line'></div></div></p>
"""

# ╔═╡ 3471a623-16af-481a-8f66-5bd1e7890188
@tracked function most_likely_failure(sys::LargeSystem, ψ; d=41, m=10000)
	# TODO: WRITE YOUR CODE HERE
end

# ╔═╡ 9c46f710-da7e-4006-a419-5ab509f94dc1
html"""
<!-- END_CODE -->
<p><div class='container'><div class='line'></div><span class='text' style='color:#B1040E'><b><code>&lt;END CODE&gt;</code></b></span><div class='line'></div></div></p>
"""

# ╔═╡ 2827a6f3-47b6-4e6f-b6ae-63271715d1f3
Markdown.parse("""
# 📊 Tests
The tests below run your `num_failures` function to see if it works properly.

This will automatically run anytime the `num_failures` function is changed and saved (due to Pluto having dependent cells).
""")

# ╔═╡ 4a91853f-9685-47f3-998a-8e0cfce688f8
Markdown.parse("""
## Running tests
Run two tests, controlling the RNG seed for deterministic outputs.
""")

# ╔═╡ 2ff6bb9c-5282-4ba1-b62e-a9fd0fe1969c
md"""
### Test 1: $n = 1000$
"""

# ╔═╡ 089581ec-8aff-4c56-9a65-26d394d5eec3
md"""
### Test 2: $n = 5000$
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

	function html_expand(title, content::Markdown.MD)
		return HTML("<details><summary>$title</summary>$(html(content))</details>")
	end

	function html_expand(title, content::Vector)
		process(str) = str isa HTML ? str.content : html(str)
		html_code = join(map(process, content))
		return HTML("<details><summary>$title</summary>$html_code</details>")
	end

	html_space() = html"<br><br><br><br><br><br><br><br><br><br><br><br><br><br>"
	html_half_space() = html"<br><br><br><br><br><br><br>"
	html_quarter_space() = html"<br><br><br>"

	function set_aspect_ratio!()
		x_range = xlims()[2] - xlims()[1]
		y_range = ylims()[2] - ylims()[1]
		plot!(ratio=x_range/y_range)
	end

	rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])

	global SEED = sum(Int.(collect("AA228V Project 1"))) # Cheeky seed value :)

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

# ╔═╡ a46702a3-4a8c-4749-bd00-52f8cce5b8ee
html_half_space()

# ╔═╡ e52ffc4f-947d-468e-9650-b6c67a57a62b
html_quarter_space()

# ╔═╡ 18754cc6-c089-4245-ad10-2848594e49b4
html_expand("Expand for useful interface functions.", [
	html"<h2hide>Useful interface functions</h2hide>",
	md"""
	The following functions are provided by `AA228V.jl` that you may use.
	""",
	html"<h3hide><code>pdf</code></h3hide>",
	md"""
**`pdf(p::TrajectoryDistribution, τ::Vector)::Float64`** — Evaluate the probability density of the trajectory `τ` using the trajectory distribution `p`.
""",
	html"<h3hide><code>rollout</code></h3hide>",
	md"""
**`rollout(sys::System; d)::Array`** — Run a single rollout of the system `sys` to a depth of `d`.
- `τ` is written as `\tau<TAB>` in code.
```julia
function rollout(sys::System; d=1)
    s = rand(Ps(sys.env))
    τ = []
    for t in 1:d
        o, a, s′ = step(sys, s) # For each rollout call, step is called d times.
        push!(τ, (; s, o, a))
        s = s′
    end
    return τ
end
```
""",
	html"<h3hide><code>isfailure</code></h3hide>",
	md"""
**`isfailure(ψ, τ)::Bool`** — Using the specification `ψ`, check if the trajector `τ` led to a failure.
- `ψ` is written as `\psi<TAB>` in code.
"""])

# ╔═╡ a0a60728-4ee0-4fd0-bd65-c056956b9712
html_expand("Expand if you get an error <code>reducing over an empty collection</code>.", md"""
The following error may occur:
> **ArgumentError**: reducing over an empty collection is not allowed; consider supplying `init` to the reducer

This is usually because there were no failures found and you are trying to iterate over an empty set. Example: `τs_failures` may be equal to `[]`, resulting in the error:
```julia
τ_most_likely = argmax(τ->pdf(pτ, τ), τs_failures)
```

**Potential solution**: Try increasing `m` to sample more rollouts.
""")

# ╔═╡ d566993e-587d-4aa3-995b-eb955dec5758
html_expand("Expand for baseline implementation using <code>DirectFalsification</code>.", [
	html"<h2hide>Using <code>DirectFalsification</code> algorithm</h2hide>",
	md"""
We could instead use the `DirectFalsification` algorithm for the small system where instead of using the `NominalTrajectoryDistribution`, we evaluate the pdf directly on the initial state distribution `ps_small`:
```julia
struct DirectFalsification
	d # depth
	m # number of samples
end

function falsify(alg::DirectFalsification, sys, ψ)
	d, m = alg.d, alg.m
	τs = [rollout(sys, d=d) for i in 1:m]
	return filter(τ->isfailure(ψ, τ), τs)
end

alg = DirectFalsification(1, 100)
τ_failures = falsify(alg, sys_small, ψ_small)
ℓτ = maximum(s->pdf(ps_small, s[1].s), τ_failures)
```
**Note**: We use the `NominalTrajectoryDistribution` to keep the algorithm general for the medium/large that _do_ have disturbances.
"""])

# ╔═╡ e888241c-b89f-4db4-ac35-6d826ec4c36c
html_expand("Expand if using optimization-based falsification.", [
	html"<h2hide>Robustness</h2hide>",
	md"""
Robustness can be a useful metric to find failures. If the robustness is $\le 0$, this indicates a failure.

- To take a gradient of _robustness_ w.r.t. a trajectory `τ`, you can use `ForwardDiff` like so:
```julia
function robustness_gradient(sys, ψ, τ)
	𝐬 = [step.s for step in τ]
	f(x) = robustness_objective(x, sys, ψ)
	return ForwardDiff.gradient(f, 𝐬)
end
```
- For the `robustness_objective` function of:
```julia
function robustness_objective(input, sys, ψ; smoothness=1.0)
	s, 𝐱 = extract(sys.env, input)
	τ = rollout(sys, s, 𝐱)
	𝐬 = [step.s for step in τ]
	return robustness(𝐬, ψ.formula, w=smoothness)
end
```
- You can then evaluate the robustness gradient of a single trajectory like so:
```julia
τ = rollout(sys_small)
robustness_gradient(sys_small, ψ_small, τ)
```
- **However**, your objective is not quite to minimize robustness.
    - **Hint**: You also want to _maximize likelihood_ (i.e., minimize negative likelihood).
""",
	html"<h2hide>Optimization-based falsification</h2hide>",
	md"""
- If you are using **Optim.jl**, the following options may be helpful (especially `f_calls_limit` for gradient free methods, `g_calls_limit` (typically n÷2) for gradient-based methods, and `iterations`): [https://julianlsolvers.github.io/Optim.jl/v0.9.3/user/config/](https://julianlsolvers.github.io/Optim.jl/v0.9.3/user/config/)
    - Optim also requires an initial guess `x0`, you can use the following for each environment (see Example 4.5 in the textbook):
```julia
x0 = initial_guess(sys::SmallSystem)  # SimpleGaussian
x0 = initial_guess(sys::MediumSystem) # InvertedPendulum
x0 = initial_guess(sys::LargeSystem)  # CollisionAvoidance

initial_guess(sys::SmallSystem) = [0.0]
initial_guess(sys::MediumSystem) = zeros(42)
initial_guess(sys::LargeSystem) = zeros(41)
```
""",
	html"<h2hide>Gradient-free optimization</h2hide>",
	md"""
If you are using _gradient free_ methods such as Nelder Mead from Optim.jl, you may need to use
```julia
iter.metadata["centroid"]
```
instead of the following from Example 4.5 in the textbook:
```julia
iter.metadata["x"]
```
""",
	html"<h2hide>Details on the <code>extract</code> function</h2hide>",
	md"""
- The `extract` function is used to _extract_ the initial state `s` and the set of disturbances `𝐱` (written `\bfx<TAB>`) so that off-the-shelf optimization algorithms (e.g., from Optim.jl) can search over the required variables.
- The `SimpleGaussian` environment only searches over initial states and has no disturbances.
```julia
function extract(env::SimpleGaussian, input)
	s = input[1]             # Objective is simply over the initial state
	𝐱 = [Disturbance(0,0,0)] # No disturbances for the SimpleGaussian
	return s, 𝐱
end
```
- **Note**: We provide the `extract` algorithms for each of the environment types:
```julia
s, 𝐱 = extract(env::SimpleGaussian, input)
s, 𝐱 = extract(env::InvertedPendulum, input)
s, 𝐱 = extract(env::CollisionAvoidance, input)
```
"""])

# ╔═╡ fda151a1-5069-44a8-baa1-d7903bc89797
html_space()

# ╔═╡ d95b0228-71b0-4cae-990e-4bab368c25d9
function plot_pendulum(sys::MediumSystem, ψ, τ=missing;
					   title="Inverted Pendulum", max_lines=100)
	plot(size=(680,350), grid=false)
	plot!(rectangle(2, 1, 0, π/4), opacity=0.5, color="#F5615C", label=false)
	plot!(rectangle(2, 1, 0, -π/4-1), opacity=0.5, color="#F5615C", label=false)
	xlabel!("Time (s)")
	ylabel!("𝜃 (rad)")
	title!(title)
	xlims!(0, 2)
	ylims!(-1.2, 1.2)
	set_aspect_ratio!()

	function plot_pendulum_traj!(τ; lw=2, α=1, color="#009E73")
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
				plot_pendulum_traj!(τᵢ; lw=1, α=0.25, color="#009E73")
			end
		end

		for τᵢ in τ_failures
			plot_pendulum_traj!(τᵢ; lw=2, α=1, color="#F5615C")
		end
	elseif τ isa Vector
		# Single trajectory
		get_color(ψ, τ) = isfailure(ψ, τ) ? "#F5615C" : "#009E73"
		get_lw(ψ, τ) = isfailure(ψ, τ) ? 2 : 1
		get_α(ψ, τ) = isfailure(ψ, τ) ? 1 : 0.25

		plot_pendulum_traj!(τ; lw=get_lw(ψ, τ), α=get_α(ψ, τ), color=get_color(ψ, τ))
	end

	return plot!()
end

# ╔═╡ 44c8fbe0-21e7-482b-84a9-c3d32a4737dd
plot_pendulum(sys_medium, ψ_medium, τs_rollout_medium; max_lines=100)

# ╔═╡ e12b102e-785b-46e9-980c-e9f7943eda60
plot_pendulum(sys_medium, ψ_medium, τ_base_medium; title="Most-likely failure")

# ╔═╡ bac5c489-553c-436f-b332-8a8e97126a51
html_quarter_space()

# ╔═╡ 420e2a64-a96b-4e12-a846-06de7cf0bae1
html_expand("Expand if using optimization-based falsification.", md"""
Note that the number of function calls `f(x)` output by the Optim results when running `display(results)` may be different than the `step_counter`.

This is because Optim counts the number of objective function calls `f` and the objective function may run `rollout` (i.e., mulitple calls to `step`) multiple times.
""")

# ╔═╡ 60ab8107-db65-4fb6-aeea-d4978aed77bd
html_space()

# ╔═╡ fd8e765e-6c38-47d2-a10f-c3f712607c77
function plot_cas(sys::LargeSystem, ψ, τ=missing; max_lines=100, title="")
	plot(size=(680,350), grid=false, xflip=true)
	xlims!(0, 40)
	ylims!(-400, 400)
	set_aspect_ratio!()
	xlabel!("\$t_\\mathrm{col}\$ (s)")
	ylabel!("\$h\$ (m)")
	title!(title)

	# Collision region
	plot!(rectangle(1, 100, 0, -50), opacity=0.5, color="#F5615C", label=false)

	function plot_cas_traj!(τ; lw=2, α=1, color="#009E73")
		X = reverse(range(0, 41, length=length(τ)))
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
				plot_cas_traj!(τᵢ; lw=1, α=0.25, color="#009E73")
			end
		end

		for τᵢ in τ_failures
			plot_cas_traj!(τᵢ; lw=2, α=1, color="#F5615C")
		end
	elseif τ isa Vector
		# Single trajectory
		get_color(ψ, τ) = isfailure(ψ, τ) ? "#F5615C" : "#009E73"
		get_lw(ψ, τ) = isfailure(ψ, τ) ? 2 : 1
		get_α(ψ, τ) = isfailure(ψ, τ) ? 1 : 0.25

		plot_cas_traj!(τ; lw=get_lw(ψ, τ), α=get_α(ψ, τ), color=get_color(ψ, τ))
	end

	return plot!()
end

# ╔═╡ aa0c4ffc-d7f0-484e-a1e2-7f6f92a3a53d
md"""
# 3️⃣ **Large**: Aircraft Collision Avoidance
The large system is an aircraft collision avoidance system.
- It uses an interpolated lookup-table policy.
- The state is comprised of the relative altitude (m) $h$, the relative vertical rate $\dot{h}$ (m/s), the previous action $a_\text{prev}$, and the time to closest point of approach $t_\text{col}$ (sec): $s = [h, \dot{h}, a_\text{prev}, t_\text{col}]$
- Actions are $a \in [-5, 0, 5]$ vertical rate changes.
- Disturbances $x$ are applied to $\dot{h}$ as sensor noise: $x \sim \mathcal{N}(0, 1.5)$

$(plot_cas(sys_large, ψ_large, τ_base_large))
"""

# ╔═╡ 797cbe41-a5f3-4179-9143-9ef6e6888a4d
plot_cas(sys_large, ψ_large, τs_rollout_large)

# ╔═╡ 74aeca7b-0658-427f-8c02-d093a0d725ee
html_space()

# ╔═╡ 83884eb4-6718-455c-b731-342471325326
# ╠═╡ disabled = true
#=╠═╡
function run_project0_test(num_failures::Function; d=100, n=1000, seed=SEED)
	Random.seed!(seed) # For determinism
	return num_failures(sys, ψ; d, n)
end
  ╠═╡ =#

# ╔═╡ b6f15d9c-33b8-40e3-be57-d91eda1c9753
#=╠═╡
begin
	test1_n = 1000
	test1_output = run_project0_test(num_failures; d=100, n=test1_n, seed=SEED)
end
  ╠═╡ =#

# ╔═╡ 522bb285-bc06-4c92-82ee-c0d0f68b184c
#=╠═╡
if isa(test1_output, Number)
	Markdown.parse("""
	The frequentist failure probability estimate for test 1 would be:
	
	\$\$\\hat{p}_{\\rm failure}^{({\\rm test}_1)} = \\frac{$(test1_output)}{$test1_n} =  $(test1_output/test1_n)\$\$
	""")
else
	md"*Update `num_failures` to get an estimated failure probability for test 1.*"
end
  ╠═╡ =#

# ╔═╡ 3314f402-10cc-434c-acbc-d38e59e4b846
#=╠═╡
begin
	test2_n = 5000
	test2_output = run_project0_test(num_failures; d=100, n=test2_n, seed=SEED)
end
  ╠═╡ =#

# ╔═╡ d72be566-6ad7-4817-8590-a504a699a4da
#=╠═╡
if isa(test2_output, Number)
	Markdown.parse("""
	The frequentist failure probability estimate for test 2 would be:
	
	\$\$\\hat{p}_{\\rm failure}^{({\\rm test}_2)} = \\frac{$(test2_output)}{$test2_n} =  $(test2_output/test2_n)\$\$
	""")
else
	md"*Update `num_failures` to get an estimated failure probability for test 2.*"
end
  ╠═╡ =#

# ╔═╡ 712e69bf-48e7-47e9-a14e-25cce64d4ae4
#=╠═╡
test2_n * 100
  ╠═╡ =#

# ╔═╡ 6302729f-b34a-4a18-921b-d194fe834208
#=╠═╡
begin
	# ⚠️ Note: PLEASE DO NOT MODIFY. Why are you in here anyhow :)?

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
  ╠═╡ =#

# ╔═╡ 5a1ed20d-788b-4655-bdd8-069545f48929
begin
	function extract(env::SimpleGaussian, input)
		s = input[1]             # Objective is simply over the initial state
		𝐱 = [Disturbance(0,0,0)] # No disturbances for the SimpleGaussian
		return s, 𝐱
	end

	function extract(env::InvertedPendulum, x)
		s = [0.0, 0.0]
		𝐱 = [Disturbance(0, 0, x[i:i+1]) for i in 1:2:length(x)]
		return s, 𝐱
	end

	function extract(env::CollisionAvoidance, x)
		s = [0.0, 0.0, 0.0, 41]
		𝐱 = [Disturbance(0, x[i], 0) for i in 1:length(x)]
		return s, 𝐱
	end

	initial_guess(sys::SmallSystem) = [0.0]
	initial_guess(sys::MediumSystem) = zeros(42)
	initial_guess(sys::LargeSystem) = zeros(4*41)

	md"> **Helper `extract` and `initial_guess` functions**."
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
	_Y = pdf.(ps_small, _X)

	# Plot the Gaussian density
	plot!(_X, _Y,
	     xlim=(-4, 4),
	     ylim=(-0.001, 0.41),
	     linecolor=dark_mode ? "white" : "black",
		 fillcolor=dark_mode ? "darkgray" : "lightgray",
		 fill=true,
	     xlabel="state \$s\$",
	     ylabel="density \$p(s)\$",
	     size=(600, 300),
	     label=false)

	# Identify the indices where x <= -2
	idx = _X .<= ψ_small.formula.ϕ.c

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
	vline!([ψ_small.formula.ϕ.c], color="crimson", label="Failure threshold")
end

# ╔═╡ ef084fea-bf4d-48d9-9c84-8cc1dd98f2d7
TableOfContents()

# ╔═╡ 97042a5e-9691-493f-802e-2262f2da4627
html"""
<style>
	h3 {
		border-bottom: 1px dotted var(--rule-color);
	}

	summary {
		font-weight: 500;
		font-style: italic;
	}

	.container {
      display: flex;
      align-items: center;
      width: 100%;
      margin: 1px 0;
    }

    .line {
      flex: 1;
      height: 2px;
      background-color: #B83A4B;
    }

    .text {
      margin: 0 5px;
      white-space: nowrap; /* Prevents text from wrapping */
    }

	h2hide {
		border-bottom: 2px dotted var(--rule-color);
		font-size: 1.8rem;
		font-weight: 700;
		margin-bottom: 0.5rem;
		margin-block-start: calc(2rem - var(--pluto-cell-spacing));
	    font-feature-settings: "lnum", "pnum";
	    color: var(--pluto-output-h-color);
	    font-family: Vollkorn, Palatino, Georgia, serif;
	    line-height: 1.25em;
	    margin-block-end: 0;
	    display: block;
	    margin-inline-start: 0px;
	    margin-inline-end: 0px;
	    unicode-bidi: isolate;
	}
	h3hide {
	    border-bottom: 1px dotted var(--rule-color);
		font-size: 1.6rem;
		font-weight: 600;
		color: var(--pluto-output-h-color);
	    font-feature-settings: "lnum", "pnum";
		font-family: Vollkorn, Palatino, Georgia, serif;
	    line-height: 1.25em;
		margin-block-start: 0;
	    margin-block-end: 0;
	    display: block;
	    margin-inline-start: 0px;
	    margin-inline-end: 0px;
	    unicode-bidi: isolate;
	}
</style>"""

# ╔═╡ Cell order:
# ╟─60f72d30-ab80-11ef-3c20-270dbcdf0cc4
# ╟─a46702a3-4a8c-4749-bd00-52f8cce5b8ee
# ╟─fd8c851a-3a42-41c5-b0fd-a12085543c9b
# ╟─17fa8557-9656-4347-9d44-213fd3b635a6
# ╠═22feee3d-4627-4358-9937-3c780b7e8bcb
# ╠═6f3e24de-094c-49dc-b892-6721b3cc54ed
# ╟─45f7c3a5-5763-43db-aba8-41ef8db39a53
# ╠═9c1daa96-76b2-4a6f-8d0e-f95d26168d2b
# ╟─370a15eb-df4b-493a-af77-00914b4616ea
# ╠═ab4c6807-5b4e-4688-b794-159e26a1599b
# ╟─0cdadb29-9fcd-4a70-9937-c24f07ce4657
# ╟─166bd412-d433-4dc9-b874-7359108c0a8b
# ╟─9132a200-f63b-444b-9830-b03cf075021b
# ╠═c2ae204e-dbcc-453a-81f5-791ba4be39db
# ╟─e73635cc-2b1e-4162-8760-b62184e70b6d
# ╠═7fe03702-25e5-473a-a92b-3b77eb753bc3
# ╟─73da2a56-8991-4484-bcde-7d397214e552
# ╟─e52ffc4f-947d-468e-9650-b6c67a57a62b
# ╟─92f20cc7-8bc0-4aea-8c70-b0f759748fbf
# ╟─f6589984-e24d-4aee-b7e7-db159ae7fea6
# ╠═fc2d34da-258c-4460-a0a4-c70b072f91ca
# ╟─c494bb97-14ef-408c-9de1-ecabe221eea6
# ╟─ec776b30-6a30-4643-a22c-e071a365d50b
# ╟─18754cc6-c089-4245-ad10-2848594e49b4
# ╟─a0a60728-4ee0-4fd0-bd65-c056956b9712
# ╟─d566993e-587d-4aa3-995b-eb955dec5758
# ╟─e888241c-b89f-4db4-ac35-6d826ec4c36c
# ╟─fda151a1-5069-44a8-baa1-d7903bc89797
# ╟─8c78529c-1e00-472c-bb76-d984b37235ab
# ╟─daada216-11d4-4f8b-807c-d347130a3928
# ╟─d18c2105-c2af-4dda-8388-617aa816a567
# ╠═77637b5e-e3ce-4ecd-90fc-95611af18002
# ╠═c4c0328d-8cb3-41d5-9740-0197cbf760c2
# ╟─b1e9bd40-a401-4630-9a1f-d61b276e72f7
# ╠═fe272c1b-421c-49de-a513-80c7bcefdd9b
# ╟─a16cf110-4afa-4792-9d3f-f13b24349886
# ╠═8b82eb8d-f6fe-4b73-8617-8c75dd65b769
# ╟─d95b0228-71b0-4cae-990e-4bab368c25d9
# ╠═44c8fbe0-21e7-482b-84a9-c3d32a4737dd
# ╠═29b0823b-c76e-43a1-b7e6-d5b809082d65
# ╟─bdb27ba8-782c-467c-818d-f68c7790e845
# ╠═3d00dc65-4c48-4988-9bb9-4cd3af6b9c5b
# ╠═e12b102e-785b-46e9-980c-e9f7943eda60
# ╟─7ef66a50-6acc-474f-b406-7b27a7b18510
# ╟─bac5c489-553c-436f-b332-8a8e97126a51
# ╟─1da9695f-b7fc-46eb-9ef9-12160246018d
# ╟─0606d827-9c70-4a79-afa7-14fb6b806546
# ╟─9657f5ff-f21c-43c5-838d-402a2a723d5e
# ╠═cb7b9b9f-59da-4851-ab13-c451c26117df
# ╟─759534ca-b40b-4824-b7ec-3a5c06cbd23e
# ╟─4943ca08-157c-40e1-acfd-bd9326082f56
# ╟─420e2a64-a96b-4e12-a846-06de7cf0bae1
# ╟─60ab8107-db65-4fb6-aeea-d4978aed77bd
# ╟─aa0c4ffc-d7f0-484e-a1e2-7f6f92a3a53d
# ╟─7d054465-9f80-4dfb-9b5f-76c3977de7cd
# ╠═1ec68a39-8de9-4fd3-be8a-26cf7706d1d6
# ╟─be426908-3fee-4ecd-b054-2497ce9a2e50
# ╠═258e14c4-9a2d-4515-9a8f-8cd96f31a6ff
# ╠═1a097a88-e4f0-4a8d-a5d6-2e3858ee417c
# ╟─fd8e765e-6c38-47d2-a10f-c3f712607c77
# ╠═797cbe41-a5f3-4179-9143-9ef6e6888a4d
# ╟─a4e0000b-4b4a-4262-bf0a-85509c4ee47e
# ╠═b5d02715-b7c9-4bf2-a284-42da40a70a68
# ╟─204feed7-cde8-40a8-b6b5-051a1c768fd9
# ╟─23fd490a-74d2-44b4-8a12-ea1460d95f85
# ╟─18a70925-3c2a-4317-8bbc-c2a096ec56d0
# ╠═3471a623-16af-481a-8f66-5bd1e7890188
# ╟─9c46f710-da7e-4006-a419-5ab509f94dc1
# ╟─74aeca7b-0658-427f-8c02-d093a0d725ee
# ╟─2827a6f3-47b6-4e6f-b6ae-63271715d1f3
# ╠═83884eb4-6718-455c-b731-342471325326
# ╟─4a91853f-9685-47f3-998a-8e0cfce688f8
# ╟─2ff6bb9c-5282-4ba1-b62e-a9fd0fe1969c
# ╠═b6f15d9c-33b8-40e3-be57-d91eda1c9753
# ╟─522bb285-bc06-4c92-82ee-c0d0f68b184c
# ╟─089581ec-8aff-4c56-9a65-26d394d5eec3
# ╠═3314f402-10cc-434c-acbc-d38e59e4b846
# ╟─d72be566-6ad7-4817-8590-a504a699a4da
# ╠═712e69bf-48e7-47e9-a14e-25cce64d4ae4
# ╟─cee165f0-049f-4ea3-8f19-04e66947a397
# ╠═6302729f-b34a-4a18-921b-d194fe834208
# ╟─ba6c082b-6e62-42fc-a85c-c8b7efc89b88
# ╟─173388ab-207a-42a6-b364-b2c1cb335f6b
# ╟─c151fc99-af4c-46ae-b55e-f50ba21f1f1c
# ╟─5a1ed20d-788b-4655-bdd8-069545f48929
# ╠═a6931d1e-08ad-4592-a54c-fd76cdc51294
# ╠═ef084fea-bf4d-48d9-9c84-8cc1dd98f2d7
# ╟─97042a5e-9691-493f-802e-2262f2da4627
