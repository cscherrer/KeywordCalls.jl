module KeywordCalls

using Compat

export @kwcall

@generated _sort(nt::NamedTuple{K}) where {K} = :(NamedTuple{($(QuoteNode.(sort(collect(K)))...),)}(nt))

_alias1(f,k) = k

@generated function _alias(f, nt::NamedTuple{K}) where {K}
    newnames = Tuple((_alias1(f,k) for k in K))
    :(NamedTuple{($(QuoteNode.(newnames)...),)}(values(nt)))
end



function _call_in_default_order end

# Thanks to @simeonschaub for this implementation 
"""
    @kwcall f(b,a,c=0)

Declares that any call `f(::NamedTuple{N})` with `sort(N) == (:a,:b,:c)`
should be dispatched to the method already defined on `f(::NamedTuple{(:b,:a,:c)})`
"""
macro kwcall(ex)
    _kwcall(ex).q
end

function _kwcall(ex)
    @assert Meta.isexpr(ex, :call)
    f = ex.args[1]
    args, defaults = _parse_args(ex.args[2:end])
    f, args, sorted_args = esc(f), QuoteNode.(args), QuoteNode.(sort(args))
    q = quote
        KeywordCalls._call_in_default_order(::typeof($f), nt::NamedTuple{($(sorted_args...),)}) = $f(NamedTuple{($(args...),)}(nt))
        $f(nt::NamedTuple) = KeywordCalls._call_in_default_order($f, _sort(merge($defaults, nt)))
        $f(; kw...) = $f(merge($defaults, NamedTuple(kw)))
    end
    return (f=f, args=args, sorted_args=sorted_args, q=q)
end

function _parse_args(args)
    # get args dropping the tail of any expressions
    _args = map(_get_arg, args)
    # get the `key = val` defaults as a NamedTuple quote
    _defaults = :((;$(filter(a -> a isa Expr, args)...)))
    return _args, _defaults
end

_get_arg(ex::Expr) = ex.args[1]
_get_arg(s::Symbol) = s

export @kwstruct 

"""
    @kwstruct Foo(b,a,c=0)

Equivalent to `@kwcall Foo(b,a,c=0)` plus a definition

    Foo(nt::NamedTuple{(:b, :a, :c), T}) where {T} = Foo{(:b, :a, :c), T}(nt)

Note that this assumes existence of a `Foo` struct of the form

    Foo{N,T} [<: SomeAbstractTypeIfYouLike]
        someFieldName :: NamedTuple{N,T}
    end
"""
macro kwstruct(ex)
    _kwstruct(ex)
end

function _kwstruct(ex)
    setup = _kwcall(ex)
    (f, args, q) = setup.f, setup.args, setup.q
    push!(q.args, :($f(nt::NamedTuple{($(args...),),T}) where {T} = $f{($(args...),), T}(nt)))

    return q
end

macro kwalias(f, aliasmap)
    _kwalias(f, aliasmap)
end

function _kwalias(f, aliasmap)
    f = esc(f)
    q = quote end
    for pair in aliasmap.args
        # Each entry should look like `:(a => b)`
        @assert pair.head = :call
        @assert pair.args[1] = :=>
        (a,b) = QuoteNode.(pairs.args[2:3])
        push!(q.args, :(KeywordCalls._alias(::typeof($f), ::Val{$a}) = $b))
    end
    return q
end
