abstract type Specification end
function evaluate(ψ::Specification, τ) end
isfailure(ψ::Specification, τ) = !evaluate(ψ, τ)

struct LTLSpecification <: Specification
	formula # formula specified using SignalTemporalLogic.jl
end
evaluate(ψ::LTLSpecification, τ) = ψ.formula([step.s for step in τ])

Broadcast.broadcastable(ψ::Specification) = Ref(ψ)
