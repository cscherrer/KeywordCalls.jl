module KeywordCalls

using Compat

export @kwcall

@generated _sort(nt::NamedTuple{K}) where {K} = :(NamedTuple{($(QuoteNode.(sort(collect(K)))...),)}(nt))

function _call_in_default_order end

# Thanks to @simeonschaub for this implementation 
"""
    @kwcall f(b,a,c)

Declares that any call `f(::NamedTuple{N})` with `sort(N) == (:a,:b,:c)`
should be dispatched to the method already defined on `f(::NamedTuple{(:b,:a,:c)})`
"""
macro kwcall(ex)
    _kwcall(ex).q
end

function _kwcall(ex)
    @assert Meta.isexpr(ex, :call)
    f = ex.args[1]
    args = ex.args[2:end]
    f, args, sorted_args = esc(f), QuoteNode.(args), QuoteNode.(sort(args))
    q = quote
        KeywordCalls._call_in_default_order(::typeof($f), nt::NamedTuple{($(sorted_args...),)}) = $f(NamedTuple{($(args...),)}(nt))
        $f(nt::NamedTuple) = KeywordCalls._call_in_default_order($f, _sort(nt))
        $f(; kw...) = $f(NamedTuple(kw))
    end
    return (f=f, args=args, sorted_args=sorted_args, q=q)
end

export @kwstruct 

"""
    @kwstruct Foo(b,a,c)

Equivalent to `@kwcall Foo(b,a,c)` plus a definition

    Foo(nt::NamedTuple{(:b, :a, :c), T}) where {T} = Foo{(:b, :a, :c), T}(nt)

Note that this assumes existence of a `Foo` struct of the form

    Foo{N,T} [<: SomeAbstractTypeIfYouLike]
        someFieldName :: NamedTuple{N,T}
    end
"""
macro kwstruct(ex)
    setup = _kwcall(ex)
    (f, args, q) = setup.f, setup.args, setup.q
    push!(q.args, :($f(nt::NamedTuple{($(args...),),T}) where {T} = $f{($(args...),), T}(nt)))

    return q
end

end
