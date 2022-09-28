# KeywordCalls

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cscherrer.github.io/KeywordCalls.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cscherrer.github.io/KeywordCalls.jl/dev)
[![Build Status](https://github.com/cscherrer/KeywordCalls.jl/workflows/CI/badge.svg)](https://github.com/cscherrer/KeywordCalls.jl/actions)
[![Coverage](https://codecov.io/gh/cscherrer/KeywordCalls.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/cscherrer/KeywordCalls.jl)


In Julia, the named tuples `(a=1, b=2)` and `(b=2, a=1)` are distinct. In some cases, it's convenient to define a method for each _set_ of names, rather than each particular ordering. 

KeywordCalls.jl lets us do this, and allows specification of a "preferred ordering" for each set of arguments.

**On Julia 1.6, this can be done with no allocation!** This is included in the unit tests. Unfortunately, the current implementation leads to allcoation in Julia 1.4 and 1.5. We hope this can be improved for better backward-compatibility, but for now we recommend using 1.6 if possible.

KeywordCalls is very light weight:
```julia
julia> @time_imports using KeywordCalls
[ Info: Precompiling KeywordCalls [4d827475-d3e4-43d6-abe3-9688362ede9f]
      0.3 ms  Compat
      0.3 ms  Tricks
      0.2 ms  KeywordCalls
```

## `@kwcall`

If we define
```julia
f(nt::NamedTuple{(:b, :a)}) = println("Calling f(b = ", nt.b,",a = ", nt.a, ")")

@kwcall f(b,a)
```

Then

```julia
julia> f(a=1,b=2)
Calling f(b = 2,a = 1)

julia> f(b=2,a=1)
Calling f(b = 2,a = 1)
```

We can define a new method for any set of arguments we like, including default values. If (after the above) we also define

```julia
f(nt::NamedTuple{(:c, :a, :b)}) = println("The sum is ", sum(values(nt)))

@kwcall f(c=0,a,b)
```

then

```julia
julia> f(a=1,b=2)
The sum is 3

julia> f(a=1,b=2,c=3)
The sum is 6
```

## `@kwalias`

It's often useful to allow multiple names to be mapped to the same interpretation. For that, we have `@kwalias`:

```julia
julia> using KeywordCalls

julia> @kwcall f(c=0,a,b)
f (generic function with 3 methods)

julia> @kwalias f [
       α     => a
       alpha => a
       β     => b
       beta  => b
       ]

julia> f(α=2,β=3)
The sum is 5

julia> f(α=2,beta=3)
The sum is 5
```

## `@kwstruct`

KeywordCalls is especially powerful when used for structs. If you have
```julia
struct Foo{N,T} [<: SomeAbstractTypeIfYouLike]
    someFieldName :: NamedTuple{N,T}
end
```

then

```julia
julia> @kwstruct Foo(μ,σ=1)
Foo

julia> Foo(σ=2,μ=4)
Foo{(:μ, :σ), Tuple{Int64, Int64}}((μ = 4, σ = 2))
```

In [MeasureTheory.jl](https://github.com/cscherrer/MeasureTheory.jl), we use this approach to allow multiple parameterizations of a given distribution.

## Related Packages

[KeywordDispatch.jl](https://github.com/simonbyrne/KeywordDispatch.jl) is very similar. When we started KeywordCalls, it seemed we would need lots of extra dependencies to make the idea work. This motivated creating a new package instead of making a PR for KeywordDispatch. @simeonschaub helped us get away from this and simplify the implementation; it's now very light-weight, and very fast.
