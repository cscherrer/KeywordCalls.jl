module KeywordCalls

using NestedTuples
using MLStyle: @match
using GeneralizedGenerated

export kwcall, @kwcall

"""
    kwcallperm(f, keys::Tuple{Symbol})

Compute the permutation required to get `keys` to the ordering declared by `@kwcall`
"""
function kwcallperm(f, keys)
    sortedkeys = Tuple(sort(collect(keys)))

    # The permutation to get from sorted order to the preferred order
    π = baseperm[(f, sortedkeys)]

    # The permutation to get from the call order to the sorted order
    σ = sortperm(collect(keys))

    # Composing the permutations
    return σ[π]
end

# `baseperm[(f, sortedargs::Tuple{Symbol})]` gives the permutation
# from sorted arguments to the ordering declared with @kwcall
const baseperm = Dict()

# can't use gensym() here, as this can lead to collisions because of precompilation
# so we use a long enough random string (130+ bits of entropy)
const KEYWORD_CALLS = Symbol("##KeywordCalls-1tqEpmTrQf0b4aJUZscoCc")

function register_calls!(list)
    for (f, sargs, π) in list
        baseperm[(f, sargs)] = π
    end
end

"""
    @kwcall f(b,a,d)

Declares that any call `f(::NamedTuple{N})` with `sort(N) == (:a,:b,:d)`
should be dispatched to the method already defined on `f(::NamedTuple{(:b,:a,:d)})`
"""
macro kwcall(call)
    if !isdefined(__module__, KEYWORD_CALLS)
        @eval __module__ module $KEYWORD_CALLS
            # Credit to Takafumi Arakaki for the idea of creating a submodule
            # within modules using KeywordCalls in order to be able to define
            # an `__init__` function which does the registration
            # (as we can't directly create/modify `__init__` for the given module).
            const perm = []
            __init__() = $register_calls!(perm)
        end
    end
    mod = getfield(__module__, KEYWORD_CALLS)
    esc(_kwcall(mod, call))
end

function _kwcall(mod::Module, call)
    @match call begin
        :($f($(args...))) => begin
            π = invperm(sortperm(collect(args)))
            sargs = Tuple(sort(args))
            targs = Tuple(args)
            quote
                # we register at precompilation time in case it's needed...
                KeywordCalls.baseperm[($f, $sargs)] = $π
                # ... but at module __init__ time, KeywordCalls.baseperm is emptied, so we
                # need to repopulate it, of which $mod takes care
                push!($mod.perm, ($f, $sargs, $π))

                $f(nt::NamedTuple) = kwcall($f, nt)

                $f(; kwargs...) = $f(kwargs.data)

                # $f($(args...)) = $f(NamedTuple{$targs}($(args...)))
            end
        end 
        _ => @error "`@kwcall` declaration must be of the form `@kwcall f(b,a,d)`"
    end
end

"""
    kwcall(f, ::NamedTuple)

Dispatch to the permuted `f(::NamedTuple)` call declared using `@kwcall`
"""
@gg function kwcall(::Type{F}, nt::NamedTuple{N}) where {F,N}
    π = Tuple(kwcallperm(F, N))
    Nπ = Tuple((N[p] for p in π))
    quote
        v = values(nt)
        valind(n) = @inbounds v[n]
        $F(NamedTuple{$Nπ}(Tuple(valind.($π))))
    end
end

@gg function kwcall(::F, nt::NamedTuple{N}) where {F<:Function,N}
    f = F.instance
    π = Tuple(kwcallperm(f, N))
    Nπ = Tuple((N[p] for p in π))
    quote
        v = values(nt)
        valind(n) = @inbounds v[n]
        $f(NamedTuple{$Nπ}(Tuple(valind.($π))))
    end
end

end # module
