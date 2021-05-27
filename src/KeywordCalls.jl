module KeywordCalls

using Compat
using Tricks

export @kwcall

@generated _sort(nt::NamedTuple{K}) where {K} = :(NamedTuple{($(QuoteNode.(sort(collect(K)))...),)}(nt))

@inline alias(f,::Val{k}) where {k} = k

alias(f, tup::Tuple) = alias.(f, tup)

function alias(f, nt::NamedTuple{K}) where {K} 
    newnames = alias(f, Val.(K))
    NamedTuple{newnames}(values(nt))
end



function _call_in_default_order end

# Thanks to @simeonschaub for this implementation 
"""
    @kwcall f(b,a,c=0)

Declares that any call `f(::NamedTuple{N})` with `sort(N) == (:a,:b,:c)`
should be dispatched to the method already defined on
`f(::NamedTuple{(:b,:a,:c)})`

Note that in the example `@kwcall f(b,a,c=0)`, the macro checks for existence of
`f(::NamedTuple)` and `f(; kwargs...)` methods, and only creates new ones if
these don't already exist.
"""
macro kwcall(ex)
    _kwcall(__module__, ex).q
end

function _kwcall(__module__, ex)
    @assert Meta.isexpr(ex, :call)
    f_sym = ex.args[1]
    f_esc = esc(f_sym)
    args, defaults = _parse_args(ex.args[2:end])

    @assert isdefined(__module__, f_sym)

    f = getproperty(__module__, f_sym)
    argnames = QuoteNode.(args)
    sorted_argnames = QuoteNode.(sort(args))

    alias = KeywordCalls.alias
    _sort = KeywordCalls._sort
    instance_type = KeywordCalls.instance_type
    q = quote
        function KeywordCalls._call_in_default_order(::$instance_type($f), nt::NamedTuple{($(sorted_argnames...),)})
            return $f_esc(NamedTuple{($(argnames...),)}(nt))
        end
    end
    
    # `namedtuplemethod` and `kwmethod` will be added to `q` if
    # 1. `f` is not defined, OR
    # 2. `f` is defined, but these methods are not
    
    namedtuplemethod = quote
        @inline function $f_esc(nt::NamedTuple)
            aliased = $alias($f, nt)
            merged = merge($defaults, aliased)
            sorted = $_sort(merged)
            return $_call_in_default_order($f, sorted)
        end
    end

    kwmethod = quote
        $f_esc(;kw...) = $f_esc(NamedTuple(kw))
    end

    if !kw_exists(f, args)
        push!(q.args, namedtuplemethod)
    end
    if !hasmethod(f, Tuple{}, (gensym(),))           
        push!(q.args, kwmethod)
    end

    return (f_esc=f_esc, args=args, defaults=defaults, sorted_argnames=sorted_argnames, q=q)
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
_get_arg(qn::QuoteNode) = qn.value

export @kwstruct 

"""
    @kwstruct Foo(b,a,c=0)

Equivalent to `@kwcall Foo(b,a,c=0)` plus a definition

    Foo(nt::NamedTuple{(:b, :a, :c), T}) where {T} = Foo{(:b, :a, :c), T}(nt)

Note that this assumes existence of a `Foo` struct of the form

    Foo{N,T} [<: SomeAbstractTypeIfYouLike]
        someFieldName :: NamedTuple{N,T}
    end

Unlike `@kwcall`, `@kwstruct` always creates a new method for generic named
tuples. This is needed because defining a struct adds a method for the constructor.
"""
macro kwstruct(ex)
    _kwstruct(__module__, ex)
end

function _kwstruct(__module__, ex)
    setup = _kwcall(__module__, ex)
    (f_esc, args, defaults, q) = setup.f_esc, setup.args, setup.defaults,  setup.q
    argnames = QuoteNode.(args)

    push!(q.args, :($f_esc(nt::NamedTuple{($(argnames...),),T}) where {T} = $f_esc{($(argnames...),), T}(nt)))
    
    return q
end

export @kwalias

"""
    @kwalias f [
        alpha => a
        beta => b
    ]

declare that for the function `f`, we should consider `alpha` to be an alias for
`a`, and `beta` to be an alias for `b`. In a call, the names will be mapped
accordingly as a pre-processing step.
"""
macro kwalias(f, aliasmap)
    _kwalias(f, aliasmap)
end

function _kwalias(f, aliasmap)
    f = esc(f)
    q = quote end
    for pair in aliasmap.args
        # Each entry should look like `:(a => b)`
        @assert pair.head == :call
        @assert pair.args[1] == :(=>)
        (a,b) = QuoteNode.(pair.args[2:3])
        push!(q.args, :(KeywordCalls.alias(::$instance_type($f), ::Val{$a}) = $b))
    end
    return q
end

function kw_exists(f, args)
    args = tuple(args...)
    nt = _sort(NamedTuple{args}(ntuple(i -> 1, length(args))))
    static_hasmethod(_call_in_default_order, Tuple{instance_type(f), typeof(nt)})
end

# See https://github.com/cscherrer/KeywordCalls.jl/issues/22
instance_type(f::F) where {F<:Function} = F
instance_type(f::UnionAll) = Type{f}

end # module
