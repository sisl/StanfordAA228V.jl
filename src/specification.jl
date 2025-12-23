abstract type Specification end
function evaluate(ψ::Specification, τ) end

"""
    isfailure(ψ::LTLSpecification, τ)::Bool

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

See also [`evaluate`](@ref), [`@formula`](@ref formulastub).
"""
isfailure(ψ::Specification, τ) = !evaluate(ψ, τ)

struct LTLSpecification <: Specification
	formula # formula specified using SignalTemporalLogic.jl
end

"""
    evaluate(ψ::LTLSpecification, τ)

TBW
"""
evaluate(ψ::LTLSpecification, τ) = ψ.formula([step.s for step in τ])

Broadcast.broadcastable(ψ::Specification) = Ref(ψ)

"""
    @formula expr

Construct a Signal Temporal Logic formula using SignalTemporalLogic.jl.

# Temporal operators
- `□(φ)`: Always (globally) - φ must hold at all time steps
- `◊(φ)`: Eventually - φ must hold at some time step
- `𝒰(φ, ψ)`: Until - φ holds until ψ becomes true

# Examples
```jldoctest
julia> using SignalTemporalLogic
julia> @formula sₜ -> sₜ > 0.0  # Atomic proposition
julia> @formula □(sₜ -> sₜ > 0.0)  # Always positive
julia> @formula ◊(sₜ -> sₜ > 0.0)  # Eventually positive

For more info see the [`SignalTemporalLogic` documentation](https://sisl.github.io/SignalTemporalLogic.jl/notebooks/runtests.html).
"""
function formulastub end
