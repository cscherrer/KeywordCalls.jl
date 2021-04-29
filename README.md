# KeywordCalls

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cscherrer.github.io/KeywordCalls.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cscherrer.github.io/KeywordCalls.jl/dev)
[![Build Status](https://github.com/cscherrer/KeywordCalls.jl/workflows/CI/badge.svg)](https://github.com/cscherrer/KeywordCalls.jl/actions)
[![Coverage](https://codecov.io/gh/cscherrer/KeywordCalls.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/cscherrer/KeywordCalls.jl)

KeywordCalls allows declarations

```julia
@kwcall f(c,b,a)
```

with the result that

- Calls to `f(x,y,z)` (without keywords) are dispatched to `f(c=x, b=y, a=z)`
- Call _with_ keywords, e.g. `f(a=z, b=y, c=x)` are put back in the declared "preferred ordering", again dispatching to `f(c=x, b=y, a=z)`

For example,
```julia
# Define a function on a NamedTuple, using your preferred ordering
julia> f(nt::NamedTuple{(:c,:b,:a)}) = nt.a + nt.b + nt.c
f (generic function with 1 method)

# Declare f to use KeywordCalls
julia> @kwcall f(c,b,a)
f (generic function with 2 methods)

# Now other orderings work too
julia> f((a=1,b=2,c=3))
6

julia> using BenchmarkTools

# And it's fast! :)
julia> @btime f((a=1,b=2,c=3))
  1.172 ns (0 allocations: 0 bytes)
6
```


Multiple declarations are allowed, as long as the set of names is distinct for each declaration of a given function.

Most of the heavy lifting is done using NestedTuples.jl and GeneralizedGenerated.jl. By taking advantage of type-level information for named tuples, we can make all of this work at compile time, so there should be no run-time overhead.
