
# Laplace distribution

export Laplace

@parameterized Laplace()

@kwstruct Laplace()
@kwstruct Laplace(μ)
@kwstruct Laplace(σ)
@kwstruct Laplace(μ, σ)
@kwstruct Laplace(λ)
@kwstruct Laplace(μ, λ)

for N in AFFINEPARS
    @eval begin
        proxy(d::Laplace{$N}) = affine(params(d), Laplace())
        @useproxy Laplace{$N}
    end
end

insupport(::Laplace, x) = true

@inline function logdensity_def(d::Laplace{()}, x)
    return -abs(x)
end

logdensity_def(d::Laplace, x) = logdensity_def(proxy(d), x)

basemeasure(::Laplace{()}) = WeightedMeasure(static(-logtwo), LebesgueMeasure())

# @affinepars Laplace

function Base.rand(rng::AbstractRNG, ::Type{T}, μ::Laplace{()}) where {T}
    rand(rng, Dists.Laplace())
end
Base.rand(rng::AbstractRNG, ::Type{T}, μ::Laplace) where {T} = Base.rand(rng, T, proxy(μ))

≪(::Laplace, ::Lebesgue{X}) where {X<:Real} = true

as(::Laplace) = asℝ
