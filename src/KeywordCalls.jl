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

function has_kwargs end
function build end

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
    
    inst = instance_type(f)
    q = quote
        function KeywordCalls._call_in_default_order(::$inst, nt::NamedTuple{($(sorted_argnames...),)})
            return $f_esc(NamedTuple{($(argnames...),)}(nt))
        end
    end

    if !static_hasmethod(has_kwargs, Tuple{inst})
        namedtuplemethod = quote
            @inline function $f_esc(nt::NamedTuple)
                aliased = $alias($f, nt)
                merged = merge($defaults, aliased)
                sorted = $_sort(merged)
                return $_call_in_default_order($f, sorted)
            end
        end

        push!(q.args, namedtuplemethod)

        kwmethod = quote
            $f_esc(;kw...) = $f_esc(NamedTuple(kw))
            KeywordCalls.has_kwargs(::$inst) = true
        end

        push!(q.args, kwmethod)
    end

    return (f_sym=f_sym, args=args, defaults=defaults, sorted_argnames=sorted_argnames, q=q)
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
    @kwstruct Foo(b,a,c)

Equivalent to `@kwcall Foo(b,a,c)` plus a definition

    Foo(nt::NamedTuple{(:b, :a, :c), T}) where {T} = Foo{(:b, :a, :c), T}(nt)

Note that this assumes existence of a `Foo` struct of the form

    Foo{N,T} [<: SomeAbstractTypeIfYouLike]
        someFieldName :: NamedTuple{N,T}
    end

NOTE: Default values (as in `@kwcall`) currently do not work for `@kwstruct`.
They can work at the REPL, but this seems to be because of a world age issue.
This feature may be supported again in a future release.
"""
macro kwstruct(ex)
    _kwstruct(__module__, ex)
end

function _kwstruct(__module__, ex)
    setup = _kwcall(__module__, ex)
    (f_sym, args, defaults, q) = setup.f_sym, setup.args, setup.defaults,  setup.q
    f_esc = esc(f_sym)
    f = getproperty(__module__, f_sym)

    # `Tricks.static_hasmethod` currently doesn't work on constructors 
    # (see https://github.com/oxinabox/Tricks.jl/issues/17)
    # But we can fake it by creating a `build` method that's defined iff the
    # constructor has the corresponding method. Then we can check for presence
    # of the `build` method and know whether the constructor method is defined.
    if !static_hasmethod(build, Tuple{instance_type(f), Tuple{NamedTuple{((args...),)}}})
        argnames = QuoteNode.(args)

        inst = instance_type(f)
        new_method = quote
            $f_esc(nt::NamedTuple{($(argnames...),),T}) where {T} = $f_esc{($(argnames...),), T}(nt)
            KeywordCalls.build(::$inst, ::NamedTuple{($(argnames...),),T}) where {T} = true
        end

        push!(q.args, new_method)
    end

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
    _kwalias(__module__, f, aliasmap)
end

function _kwalias(__module__, fsym, aliasmap)
    f_esc = esc(fsym)
    f = getproperty(__module__, fsym)
    q = quote end
    for pair in aliasmap.args
        # Each entry should look like `:(a => b)`
        @assert pair.head == :call
        @assert pair.args[1] == :(=>)
        (a,b) = QuoteNode.(pair.args[2:3])

        
        inst = instance_type(f)
        newmethod = quote
            KeywordCalls.alias(::$inst, ::Val{$a}) = $b
        end

        push!(q.args, newmethod)
    end
    return q
end

# See https://github.com/cscherrer/KeywordCalls.jl/issues/22
@inline instance_type(f::F) where {F<:Function} = F
@inline instance_type(f::UnionAll) = Type{f}


end # module
