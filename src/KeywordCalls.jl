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
    π = baseperm[(f, sortedkeys)]
    σ = sortperm(collect(keys))
    return σ[π]
end

"""
    baseperm(f, ::Val)


"""
const baseperm = Dict()




macro kwcall(call)
    esc(_kwcall(call))
end

function _kwcall(call)
    @match call begin
        :($f($(args...))) => begin
            π = invperm(sortperm(collect(args)))
            sargs = Tuple(sort(args))
            quote
                KeywordCalls.baseperm[($f, $sargs)] = $π

                $f(nt::NamedTuple) = kwcall($f, nt)
            end
        end 
        _ => @error "`@kwcall` declaration must be of the form `@kwcall f(b,a,d)`"
    end
end


@gg function kwcall(::F, nt::NamedTuple{N}) where {F,N}
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
