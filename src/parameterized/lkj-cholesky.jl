# Modified from
# https://github.com/tpapp/AltDistributions.jl

# See also the Stan manual (the "Stanual", though nobody calls it that)
# https://mc-stan.org/docs/2_27/reference-manual/cholesky-factors-of-correlation-matrices-1.html

export LKJCholesky
using PositiveFactorizations

const CorrCholeskyUpper = TV.CorrCholeskyFactor

@doc """
    LKJCholesky(k=3, η=1.0)
    LKJCholesky(k=3, logη=0.0)

`LKJCholesky(k, ...)` gives the `k×k` LKJ distribution (Lewandowski et al 2009)
expressed as a Cholesky decomposition. As a special case, for
`C = rand(LKJCholesky(k=K, η=1.0))` (or equivalently
`C=rand(LKJCholesky{k}(k=K, logη=0.0))`), `C.L * C.U` is uniform over the set of
all `K×K` correlation matrices. Note, however, that in this case `C.L` and `C.U`
are **not** sampled uniformly (because the multiplication is nonlinear).

The `logdensity` method for this measure applies for `LowerTriangular`,
`UpperTriangular`, or `Diagonal` matrices, and will "do the right thing". The
`logdensity` **does not check if `L*U` yields a valid correlation matrix**.

Valid values are ``η > 0``. When ``η > 1``, the distribution is unimodal with a
peak at `I`, while ``0 < η < 1`` yields a trough. ``η = 2`` is recommended as a vague prior.

Adapted from
https://github.com/tpapp/AltDistributions.jl
""" LKJCholesky

@parameterized LKJCholesky(k, η)

@kwstruct LKJCholesky(k, η)
@kwstruct LKJCholesky(k, logη)

LKJCholesky(k::Integer) = LKJCholesky(k, 1.0)

asparams(::Type{<:LKJCholesky}, ::StaticSymbol{:η}) = asℝ₊
asparams(::Type{<:LKJCholesky}, ::StaticSymbol{:logη}) = asℝ

# Modified from
# https://github.com/tpapp/AltDistributions.jl

using LinearAlgebra

logdensity_def(d::LKJCholesky, C::Cholesky) = logdensity_def(d, C.UL)

@inline function logdensity_def(
    d::LKJCholesky{(:k, :η)},
    L::Union{LinearAlgebra.AbstractTriangular,Diagonal},
)
    η = d.η
    # z = diag(L)
    # sum(log.(z) .* ((k:-1:1) .+ 2*(η-1)))

    # Note: https://github.com/cscherrer/MeasureTheory.jl/issues/100#issuecomment-852428192
    c = d.k + 2(η - 1)
    n = size(L, 1)
    s = sum(1:n) do i
        (c - i) * @inbounds log(L[i, i])
    end
    return s
end

@inline function logdensity_def(
    d::LKJCholesky{(:k, :logη)},
    L::Union{LinearAlgebra.AbstractTriangular,Diagonal},
)
    c = d.k + 2 * expm1(d.logη)
    n = size(L, 1)
    s = sum(1:n) do i
        (c - i) * @inbounds log(L[i, i])
    end
    return s
end

as(d::LKJCholesky) = CorrCholesky(d.k)

@inline function basemeasure(d::LKJCholesky{(:k, :η)})
    t = as(d)
    base = Pushforward(t, LebesgueMeasure()^TV.dimension(t), False())
    WeightedMeasure(Dists.lkj_logc0(d.k, d.η), base)
end

@inline function basemeasure(d::LKJCholesky{(:k, :logη)})
    t = as(d)
    η = exp(d.logη)
    base = Pushforward(t, LebesgueMeasure()^TV.dimension(t), False())
    WeightedMeasure(Dists.lkj_logc0(d.k, η), base)
end

# TODO: Fix this
insupport(::LKJCholesky, x) = true

# Note (from @sethaxen): this can be done without the cholesky decomposition, by randomly
# sampling the canonical partial correlations, as in the LKJ paper, and then
# mapping them to the cholesky factor instead of the correlation matrix. Stan
# implements* this. But that can be for a future PR. 
#
# * https://github.com/stan-dev/math/blob/develop/stan/math/prim/prob/lkj_corr_cholesky_rng.hpp
function Base.rand(rng::AbstractRNG, ::Type, d::LKJCholesky{(:k, :η)})
    return cholesky(Positive, rand(rng, Dists.LKJ(d.k, d.η)))
end;

function testvalue(d::LKJCholesky)
    t = CorrCholesky(d.k)
    return TV.transform(t, zeros(TV.dimension(t)))
end

function Base.rand(rng::AbstractRNG, ::Type, d::LKJCholesky{(:k, :logη)})
    return cholesky(Positive, rand(rng, Dists.LKJ(d.k, exp(d.logη))))
end;

ConstructionBase.constructorof(::Type{L}) where {L<:LKJCholesky} = LKJCholesky
