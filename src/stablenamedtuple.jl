struct StableNamedTuple{names,T}
    values::T
end

@eval function StableNamedTuple{names,T}(args::Tuple) where {names, T <: Tuple}
    if length(args) != length(names::Tuple)
        throw(ArgumentError("Wrong number of arguments to named tuple constructor."))
    end
    # Note T(args) might not return something of type T; e.g.
    # Tuple{Type{Float64}}((Float64,)) returns a Tuple{DataType}
    $(Expr(:splatnew, :(StableNamedTuple{names,T}), :(T(args))))
end

@generated function StableNamedTuple{names, T}(nt::StableNamedTuple) where {names, T <: Tuple}
    Expr(:new, :(StableNamedTuple{names, T}),
         Any[ :(convert(fieldtype(T, $n), getfield(nt, $(QuoteNode(names[n]))))) for n in 1:length(names) ]...)
end

@generated function StableNamedTuple{names}(nt::StableNamedTuple) where {names}
    idx = Int[ Base.fieldindex(nt, names[n]) for n in 1:length(names) ]
    types = Tuple{(fieldtype(nt, idx[n]) for n in 1:length(idx))...}
    Expr(:new, :(StableNamedTuple{names, $types}), Any[ :(getfield(nt, $(idx[n]))) for n in 1:length(idx) ]...)
end

StableNamedTuple{names, T}(itr) where {names, T <: Tuple} = StableNamedTuple{names, T}(T(itr))
StableNamedTuple{names}(itr) where {names} = StableNamedTuple{names}(Tuple(itr))

StableNamedTuple(itr) = (; itr...)

# avoids invalidating Union{}(...)
StableNamedTuple{names, Union{}}(itr::Tuple) where {names} = throw(MethodError(StableNamedTuple{names, Union{}}, (itr,)))


Base.length(t::StableNamedTuple) = nfields(t)
Base.iterate(t::StableNamedTuple, iter=1) = iter > nfields(t) ? nothing : (getfield(t, iter), iter + 1)
Base.rest(t::StableNamedTuple) = t
@inline Base.rest(t::StableNamedTuple{names}, i::Int) where {names} = StableNamedTuple{Base.rest(names,i)}(t)
Base.firstindex(t::StableNamedTuple) = 1
Base.lastindex(t::StableNamedTuple) = nfields(t)
Base.getindex(t::StableNamedTuple, i::Int) = getfield(t, i)
Base.getindex(t::StableNamedTuple, i::Symbol) = getfield(t, i)
@inline Base.getindex(t::StableNamedTuple, idxs::Tuple{Vararg{Symbol}}) = StableNamedTuple{idxs}(t)
@inline Base.getindex(t::StableNamedTuple, idxs::AbstractVector{Symbol}) = StableNamedTuple{Tuple(idxs)}(t)
Base.indexed_iterate(t::StableNamedTuple, i::Int, state=1) = (getfield(t, i), i+1)
Base.isempty(::StableNamedTuple{()}) = true
Base.isempty(::StableNamedTuple) = false
Base.empty(::StableNamedTuple) = StableNamedTuple()

prevind(@nospecialize(t::StableNamedTuple), i::Integer) = Int(i)-1
nextind(@nospecialize(t::StableNamedTuple), i::Integer) = Int(i)+1

convert(::Type{StableNamedTuple{names,T}}, nt::StableNamedTuple{names,T}) where {names,T<:Tuple} = nt
convert(::Type{StableNamedTuple{names}}, nt::StableNamedTuple{names}) where {names} = nt

function convert(::Type{StableNamedTuple{names,T}}, nt::StableNamedTuple{names}) where {names,T<:Tuple}
    StableNamedTuple{names,T}(T(nt))
end

if nameof(@__MODULE__) === :Base
    Tuple(nt::StableNamedTuple) = (nt...,)
    (::Type{T})(nt::StableNamedTuple) where {T <: Tuple} = convert(T, Tuple(nt))
end

function show(io::IO, t::StableNamedTuple)
    n = nfields(t)
    for i = 1:n
        # if field types aren't concrete, show full type
        if typeof(getfield(t, i)) !== fieldtype(typeof(t), i)
            show(io, typeof(t))
            print(io, "(")
            show(io, Tuple(t))
            print(io, ")")
            return
        end
    end
    if n == 0
        print(io, "StableNamedTuple()")
    else
        typeinfo = get(io, :typeinfo, Any)
        print(io, "(")
        for i = 1:n
            show_sym(io, fieldname(typeof(t), i))
            print(io, " = ")
            show(IOContext(io, :typeinfo =>
                           t isa typeinfo <: StableNamedTuple ? fieldtype(typeinfo, i) : Any),
                 getfield(t, i))
            if n == 1
                print(io, ",")
            elseif i < n
                print(io, ", ")
            end
        end
        print(io, ")")
    end
end

Base.eltype(::Type{T}) where T<:StableNamedTuple = Base.nteltype(T)
Base.nteltype(::Type) = Any
Base.nteltype(::Type{StableNamedTuple{names,T}} where names) where {T} = eltype(T)

Base.:(==)(a::StableNamedTuple{n}, b::StableNamedTuple{n}) where {n} = Tuple(a) == Tuple(b)
Base.:(==)(a::StableNamedTuple, b::StableNamedTuple) = false

Base.isequal(a::StableNamedTuple{n}, b::StableNamedTuple{n}) where {n} = isequal(Tuple(a), Tuple(b))
Base.isequal(a::StableNamedTuple, b::StableNamedTuple) = false

_nt_names(::StableNamedTuple{names}) where {names} = names
_nt_names(::Type{T}) where {names,T<:StableNamedTuple{names}} = names

Base.hash(x::StableNamedTuple, h::UInt) = xor(objectid(_nt_names(x)), hash(Tuple(x), h))

Base.:(<)(a::StableNamedTuple{n}, b::StableNamedTuple{n}) where {n} = Tuple(a) < Tuple(b)
Base.isless(a::StableNamedTuple{n}, b::StableNamedTuple{n}) where {n} = isless(Tuple(a), Tuple(b))

Base.same_names(::StableNamedTuple{names}...) where {names} = true
Base.same_names(::StableNamedTuple...) = false

# NOTE: this method signature makes sure we don't define map(f)
function Base.map(f, nt::StableNamedTuple{names}, nts::StableNamedTuple...) where names
    if !Base.same_names(nt, nts...)
        throw(ArgumentError("Named tuple names do not match."))
    end
    StableNamedTuple{names}(map(f, map(Tuple, (nt, nts...))...))
end

Base.@pure function merge_names(an::Tuple{Vararg{Symbol}}, bn::Tuple{Vararg{Symbol}})
    @nospecialize an bn
    names = Symbol[an...]
    for n in bn
        if !Base.sym_in(n, an)
            push!(names, n)
        end
    end
    (names...,)
end

Base.@pure function merge_types(names::Tuple{Vararg{Symbol}}, a::Type{<:StableNamedTuple}, b::Type{<:StableNamedTuple})
    @nospecialize names a b
    bn = _nt_names(b)
    return Tuple{Any[ fieldtype(Base.sym_in(names[n], bn) ? b : a, names[n]) for n in 1:length(names) ]...}
end

"""
    merge(a::StableNamedTuple, bs::StableNamedTuple...)

Construct a new named tuple by merging two or more existing ones, in a left-associative
manner. Merging proceeds left-to-right, between pairs of named tuples, and so the order of fields
present in both the leftmost and rightmost named tuples take the same position as they are found in the
leftmost named tuple. However, values are taken from matching fields in the rightmost named tuple that
contains that field. Fields present in only the rightmost named tuple of a pair are appended at the end.
A fallback is implemented for when only a single named tuple is supplied,
with signature `merge(a::StableNamedTuple)`.

!!! compat "Julia 1.1"
    Merging 3 or more `StableNamedTuple` requires at least Julia 1.1.

# Examples
```jldoctest
julia> merge((a=1, b=2, c=3), (b=4, d=5))
(a = 1, b = 4, c = 3, d = 5)
```

```jldoctest
julia> merge((a=1, b=2), (b=3, c=(d=1,)), (c=(d=2,),))
(a = 1, b = 3, c = (d = 2,))
```
"""
@generated function Base.merge(a::StableNamedTuple{an}, b::StableNamedTuple{bn}) where {an, bn}
    names = merge_names(an, bn)
    types = merge_types(names, a, b)
    vals = Any[ :(getfield($(sym_in(names[n], bn) ? :b : :a), $(QuoteNode(names[n])))) for n in 1:length(names) ]
    :( StableNamedTuple{$names,$types}(($(vals...),)) )
end

merge(a::StableNamedTuple,     b::StableNamedTuple{()}) = a
merge(a::StableNamedTuple{()}, b::StableNamedTuple{()}) = a
merge(a::StableNamedTuple{()}, b::StableNamedTuple)     = b

merge(a::StableNamedTuple, b::Iterators.Pairs{<:Any,<:Any,<:Any,<:StableNamedTuple}) = merge(a, getfield(b, :data))

merge(a::StableNamedTuple, b::Iterators.Zip{<:Tuple{Any,Any}}) = merge(a, StableNamedTuple{Tuple(b.is[1])}(b.is[2]))

merge(a::StableNamedTuple, b::StableNamedTuple, cs::StableNamedTuple...) = merge(merge(a, b), cs...)

merge(a::StableNamedTuple) = a

"""
    merge(a::StableNamedTuple, iterable)

Interpret an iterable of key-value pairs as a named tuple, and perform a merge.

```jldoctest
julia> merge((a=1, b=2, c=3), [:b=>4, :d=>5])
(a = 1, b = 4, c = 3, d = 5)
```
"""
function merge(a::StableNamedTuple, itr)
    names = Symbol[]
    vals = Any[]
    inds = IdDict{Symbol,Int}()
    for (k, v) in itr
        k = k::Symbol
        oldind = get(inds, k, 0)
        if oldind > 0
            vals[oldind] = v
        else
            push!(names, k)
            push!(vals, v)
            inds[k] = length(names)
        end
    end
    merge(a, StableNamedTuple{(names...,)}((vals...,)))
end

keys(nt::StableNamedTuple{names}) where {names} = names
values(nt::StableNamedTuple) = Tuple(nt)
haskey(nt::StableNamedTuple, key::Union{Integer, Symbol}) = isdefined(nt, key)
get(nt::StableNamedTuple, key::Union{Integer, Symbol}, default) = haskey(nt, key) ? getfield(nt, key) : default
get(f::Base.Callable, nt::StableNamedTuple, key::Union{Integer, Symbol}) = haskey(nt, key) ? getfield(nt, key) : f()
tail(t::StableNamedTuple{names}) where names = StableNamedTuple{tail(names)}(t)
front(t::StableNamedTuple{names}) where names = StableNamedTuple{front(names)}(t)

Base.@pure function diff_names(an::Tuple{Vararg{Symbol}}, bn::Tuple{Vararg{Symbol}})
    @nospecialize an bn
    names = Symbol[]
    for n in an
        if !Base.sym_in(n, bn)
            push!(names, n)
        end
    end
    (names...,)
end

"""
    structdiff(a::StableNamedTuple{an}, b::Union{StableNamedTuple{bn},Type{StableNamedTuple{bn}}}) where {an,bn}

Construct a copy of named tuple `a`, except with fields that exist in `b` removed.
`b` can be a named tuple, or a type of the form `StableNamedTuple{field_names}`.
"""
@generated function structdiff(a::StableNamedTuple{an}, b::Union{StableNamedTuple{bn}, Type{StableNamedTuple{bn}}}) where {an, bn}
    names = diff_names(an, bn)
    idx = Int[ Base.fieldindex(a, names[n]) for n in 1:length(names) ]
    types = Tuple{Any[ fieldtype(a, idx[n]) for n in 1:length(idx) ]...}
    vals = Any[ :(getfield(a, $(idx[n]))) for n in 1:length(idx) ]
    :( StableNamedTuple{$names,$types}(($(vals...),)) )
end

structdiff(a::StableNamedTuple{an}, b::Union{StableNamedTuple{an}, Type{StableNamedTuple{an}}}) where {an} = (;)

"""
    setindex(nt::StableNamedTuple, val, key::Symbol)

Constructs a new `StableNamedTuple` with the key `key` set to `val`.
If `key` is already in the keys of `nt`, `val` replaces the old value.

```jldoctest
julia> nt = (a = 3,)
(a = 3,)

julia> Base.setindex(nt, 33, :b)
(a = 3, b = 33)

julia> Base.setindex(nt, 4, :a)
(a = 4,)

julia> Base.setindex(nt, "a", :a)
(a = "a",)
```
"""
function setindex(nt::StableNamedTuple, v, idx::Symbol)
    merge(nt, (; idx => v))
end

"""
    @StableNamedTuple{key1::Type1, key2::Type2, ...}
    @StableNamedTuple begin key1::Type1; key2::Type2; ...; end

This macro gives a more convenient syntax for declaring `StableNamedTuple` types. It returns a `StableNamedTuple`
type with the given keys and types, equivalent to `StableNamedTuple{(:key1, :key2, ...), Tuple{Type1,Type2,...}}`.
If the `::Type` declaration is omitted, it is taken to be `Any`.   The `begin ... end` form allows the
declarations to be split across multiple lines (similar to a `struct` declaration), but is otherwise
equivalent.

For example, the tuple `(a=3.1, b="hello")` has a type `StableNamedTuple{(:a, :b),Tuple{Float64,String}}`, which
can also be declared via `@StableNamedTuple` as:

```jldoctest
julia> @StableNamedTuple{a::Float64, b::String}
StableNamedTuple{(:a, :b), Tuple{Float64, String}}

julia> @StableNamedTuple begin
           a::Float64
           b::String
       end
StableNamedTuple{(:a, :b), Tuple{Float64, String}}
```

!!! compat "Julia 1.5"
    This macro is available as of Julia 1.5.
"""
macro StableNamedTuple(ex)
    Meta.isexpr(ex, :braces) || Meta.isexpr(ex, :block) ||
        throw(ArgumentError("@StableNamedTuple expects {...} or begin...end"))
    decls = filter(e -> !(e isa LineNumberNode), ex.args)
    all(e -> e isa Symbol || Meta.isexpr(e, :(::)), decls) ||
        throw(ArgumentError("@StableNamedTuple must contain a sequence of name or name::type expressions"))
    vars = [QuoteNode(e isa Symbol ? e : e.args[1]) for e in decls]
    types = [esc(e isa Symbol ? :Any : e.args[2]) for e in decls]
    return :(StableNamedTuple{($(vars...),), Tuple{$(types...)}})
end
