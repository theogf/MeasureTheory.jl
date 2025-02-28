# Multinomial distribution

export Multinomial

@parameterized Multinomial(n, p)

basemeasure(d::Multinomial) = CountingMeasure()

@inline function insupport(d::Multinomial{(:n, :p)}, x)
    length(x) == length(d.p) || return false
    all(isinteger, x) || return false
    sum(x) == d.n || return false
    return true
end

@kwstruct Multinomial(n, p)

@inline function logdensity_def(d::Multinomial{(:n, :p)}, x)
    p = d.p
    s = 0.0
    for j in eachindex(x)
        s += xlogy(x[j], p[j])
    end
    return s
end

function Base.rand(rng::AbstractRNG, T::Type, μ::Multinomial)
    rand(rng, Dists.Multinomial(μ.n, μ.p))
end

proxy(d::Multinomial{(:p,)}) = Dists.Multinomial(d.n, d.p)

# Based on
# https://github.com/JuliaMath/Combinatorics.jl/blob/c2114a71ccfc93052efb9a9379e62b81b9388ef8/src/factorials.jl#L99
function logmultinomial(k)
    s = 0
    result = 1
    @inbounds for i in k
        s += i
        (Δresult, _) = logabsbinomial(s, i)
        result += Δresult
    end
    result
end

function testvalue(d::Multinomial{(:n, :p)})
    n = d.n
    l = length(d.p)
    q, r = divrem(n, l)
    x = fill(q, l)
    x[1] += r
    return x
end
