module KeywordCalls

using Compat

export @kwcall

@generated _sort(nt::NamedTuple{K}) where {K} = :(NamedTuple{($(QuoteNode.(sort(collect(K)))...),)}(nt))

function _call_in_default_order end

# Thanks to @simeonschaub for this implementation 
"""
@kwcall f(b,a,d)

Declares that any call `f(::NamedTuple{N})` with `sort(N) == (:a,:b,:d)`
should be dispatched to the method already defined on `f(::NamedTuple{(:b,:a,:d)})`
"""
macro kwcall(ex)
    @assert Meta.isexpr(ex, :call)
    f = ex.args[1]
    args = ex.args[2:end]
    f, args, sorted_args = esc(f), QuoteNode.(args), QuoteNode.(sort(args))
    return quote
        KeywordCalls._call_in_default_order(::typeof($f), nt::NamedTuple{($(sorted_args...),)}) = $f(NamedTuple{($(args...),)}(nt))
        $f(nt::NamedTuple) = KeywordCalls._call_in_default_order($f, _sort(nt))
        $f(; kw...) = $f(NamedTuple(kw))
    end
end

struct Foo{N,T} <: Bar
    nt::NamedTuple{N,T}
end


Foo(nt::NamedTuple{(:μ,:σ),T}) where {T} = Foo{(:μ,:σ), T}(nt)

end
