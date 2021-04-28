module KeywordCalls

using NestedTuples
using MLStyle: @match

macro kwcall(call)
    esc(_kwcall(call))
end

function _kwcall(call)
    @match call begin
        $f($(...)) => begin
            quote
                getCalls($f, 

                $f(; kwargs...) = 
            end
        end 
    end
end

function f end

function mysort(::typeof(f), 

@generated function paramsort(nt::NamedTuple{K,V}) where {K,V}
    s = _paramsort(schema(nt))
    ℓ = Lenses(lenses(s))
    return :(leaf_setter($s)($ℓ(nt)...))
end

_paramsort(nt::NamedTuple{(), Tuple{}}) = nt

@gg function ntsortperm(nt::NamedTuple{N,T}) where {N,T}
    π = sortperm(collect(N))
    π
end

function ntpermute(nt::NamedTuple{N,T}, π::Vector{Int}) where {N,T}
    newnames = N[π]
    newvals = values(nt)[π]
    NamedTuple{N[π]}(values(nt)[π])
end

function _argsort(nt::NamedTuple{K,V}) where {K,V}
    # Assign each symbol a default rank
    π = sortperm(collect(K))
    k = K[π]


    v = @inbounds (_paramsort.(values(nt)))[π]
    return namedtuple(k)(v)
end

_paramsort(t::Tuple) = _paramsort.(t)
_paramsort(x) = x


@gg function kwcall(f, args::NamedTuple{N,T}) where {N,T}
    
end

mysort(f, keysort(args))


if !isempty(p)
    # e.g. Normal(μ,σ) = Normal(;μ=μ, σ=σ)
    # Requires Julia 1.5
    pnames = QuoteNode.(p)
    # push!(q.args, :($μ($(p...)) = $μ(;$(p...))))
    push!(q.args, :($μ($(p...)) = $μ(;$(p...))))
end

# Write your package code here.


myorder(

end
