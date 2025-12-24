abstract type Specification end
function evaluate(ψ::Specification, τ) end

"""
    isfailure(ψ::LTLSpecification, τ)

Return `true` if the states in trajectory `τ` fail to satisfy specification `ψ`, `false` otherwise.
Logical inverse of [`evaluate`](@ref).

# Examples
```jldoctest isfailure
julia> using SignalTemporalLogic, StanfordAA228V

julia> τ = [(s=2.0, ), (s=1.0, ), (s=-1.0, )];

julia> μ = @formula sₜ -> sₜ < 0.0;

julia> ψ₁ = LTLSpecification(@formula □(μ));  # always

julia> isfailure(ψ₁, τ)
true

julia> ψ₂ = LTLSpecification(@formula ◊(μ));  # eventually

julia> isfailure(ψ₂, τ)
false
```

We can do the same for system rollouts.
```jldoctest isfailure
julia> sys = System(ProportionalController([0, 0]),
                    InvertedPendulum(),
                    IdealSensor());

julia> τ = rollout(sys; d=20);

julia> ψ₃ = LTLSpecification(@formula □(sₜ -> abs(sₜ[1]) < deg2rad(5)));

julia> isfailure(ψ₃, τ)
true
```

See also [`evaluate`](@ref), [`@formula`](@ref formulastub), [`LTLSpecification`](@ref).
"""
isfailure(ψ::Specification, τ) = !evaluate(ψ, τ)

"""
    LTLSpecification <: Specification

A specification of a formula using *linear temporal logic* ([kochenderfer2026validation; Chapter 3.5.1](@citet)).
Formulas are specified using [`@formula`](@ref formulastub) from [`SignalTemporalLogic.jl`](https://github.com/sisl/SignalTemporalLogic.jl).

# Example
```jldoctest
julia> using SignalTemporalLogic, StanfordAA228V

julia> τ = [(s=2.0, ), (s=1.0, ), (s=-1.0, )];  # typically from system rollout

julia> ψ = LTLSpecification(@formula ◊(sₜ -> sₜ < 0.0));  # eventually

julia> evaluate(ψ, τ)
true
```

See also [`evaluate`](@ref), [`isfailure`](@ref), [`@formula`](@ref formulastub), [`rollout`](@ref).
"""
struct LTLSpecification <: Specification
	formula # formula specified using SignalTemporalLogic.jl
end

"""
    evaluate(ψ::LTLSpecification, τ)

Return `true` if the states in trajectory `τ` satisfy the specification `ψ`, `false` otherwise.
Logical inverse of [`isfailure`](@ref).

See also [`isfailure`](@ref) for an example.
"""
evaluate(ψ::LTLSpecification, τ) = ψ.formula([step.s for step in τ])

Broadcast.broadcastable(ψ::Specification) = Ref(ψ)

"""
    @formula expr

Construct a Signal Temporal Logic formula using [`SignalTemporalLogic.jl`](https://github.com/sisl/SignalTemporalLogic.jl).
See [kochenderfer2026validation; Chapter 3.4-3.5](@citet).

# Temporal operators
- `□(φ)`: Always (globally) - φ must hold at all time steps
- `◊(φ)`: Eventually - φ must hold at some time step
- `𝒰(φ, ψ)`: Until - φ holds until ψ becomes true

# Examples
```julia
julia> using SignalTemporalLogic
julia> @formula sₜ -> sₜ > 0.0  # Atomic proposition
julia> @formula □(sₜ -> sₜ > 0.0)  # Always positive. Type as `\\square<TAB>`
julia> @formula ◊(sₜ -> sₜ > 0.0)  # Eventually positive. Type as `\\lozenge<TAB>`
```

For more info see the [`SignalTemporalLogic` documentation](https://sisl.github.io/SignalTemporalLogic.jl/notebooks/runtests.html).
"""
function formulastub end
