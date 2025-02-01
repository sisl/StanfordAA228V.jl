struct AvoidSetSpecification <: Specification
    set # avoid set
end

evaluate(ψ::AvoidSetSpecification, τ) = all(vec(step.s) ∉ ψ.set for step in τ)

¬(ψ::AvoidSetSpecification) = ψ.set

function disturbance_set(sys)
    Do = sys.sensor.Do
    low = [support(d).lb for d in Do.v]
    high = [support(d).ub for d in Do.v]
    return Disturbance(ZeroSet(1), ZeroSet(2), Hyperrectangle(; low, high))
end

function subset_vertices(ℛ::UnionSet)
    curr_set = ℛ
    vertices = []
    while curr_set isa UnionSet
        push!(vertices, collect(LazySets.plot_vlist(curr_set[2], 0)))
        curr_set = curr_set[1]
    end
    push!(vertices, collect(LazySets.plot_vlist(curr_set, 0)))
    return vertices
end

extract_set(R) = R
function extract_set(R::UnionSet)
    ls = LazySet[]
    for s in array(R)
        ls = vcat(ls, extract_set(s))
    end
    return ls
end

count_vertices(u::UnionSet) = reduce(vcat, [count_vertices(uᵢ) for uᵢ in u])
count_vertices(u) = length(LazySets.vertices(u))

fan_sets(u::UnionSet) = reduce(vcat, [fan_sets(uᵢ) for uᵢ in u])
fan_sets(u) = u

function bounded_set(ℛt, ℛmax)
    ℛt = concretize(ℛt)
    if ℛmax ⊆ box_approximation(ℛt)
        ℛbounded = ℛmax
    else
        ℛbounded = ℛt
    end
    return ℛbounded
end

function bounded_wrapper(ℛ, ℛmax)
    return map(ℛt->bounded_set(ℛt, ℛmax), ℛ)
end
