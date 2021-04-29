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
julia> f(nt::NamedTuple{(:c,:b,:a)}) = nt.a^3 + nt.b^2 + nt.c
f (generic function with 1 method)

# Declare f to use KeywordCalls
julia> @kwcall f(c,b,a)
f (generic function with 4 methods)

# Here are the 4 methods
julia> methods(f)
# 4 methods for generic function "f":
[1] f(; kwargs...) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:52
[2] f(nt::NamedTuple{(:c, :b, :a), T} where T<:Tuple) in Main at REPL[2]:1
[3] f(nt::NamedTuple) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:50
[4] f(c, b, a) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:54

# Now other orderings work too. Here's passing a `NamedTuple`:
julia> f((a=1,b=2,c=3))
8

# Or kwargs...
julia> f(a=1,b=2,c=3)
8

# Unnamed arguments expect the declared `(c,b,a)` ordering:
julia> f(1,2,3)
32
```


Multiple declarations are allowed, as long as the set of names is distinct for each declaration of a given function.

Most of the heavy lifting is done using NestedTuples.jl and GeneralizedGenerated.jl. By taking advantage of type-level information for named tuples, we can make all of this work at compile time.

## Limitations

KeywordCalls tries to push as much of the work as possible to the compiler, to make repeated run-time calls fast. But there's no free lunch, you either pay now or pay later.

If you'd rather avoid the compilation time (at the cost of some runtime overhead), you should try [KeywordDispatch.jl](https://github.com/simonbyrne/KeywordDispatch.jl).

## Benchmarks

Let's define a method for each "alphabet prefix":
```julia
letters = Symbol.('a':'z')

for n in 1:26
    fkeys = Tuple(letters[1:n])

    @eval begin
        f(nt::NamedTuple{$fkeys}) = sum(values(nt))
        $(KeywordCalls._kwcall(:(f($(fkeys...)))))
    end
end
```

So now `f`'s methods look like this:
```julia
julia> methods(f)
# 54 methods for generic function "f":
[1] f(; kwargs...) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:52
[2] f(nt::NamedTuple{(:a,), T} where T<:Tuple) in Main at REPL[27]:5
[3] f(nt::NamedTuple{(:a, :b), T} where T<:Tuple) in Main at REPL[27]:5
[4] f(nt::NamedTuple{(:a, :b, :c), T} where T<:Tuple) in Main at REPL[27]:5
⋮
[26] f(nt::NamedTuple{(:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t, :u, :v, :w, :x, :y), T} where T<:Tuple) in Main at REPL[27]:5
[27] f(nt::NamedTuple{(:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t, :u, :v, :w, :x, :y, :z), T} where T<:Tuple) in Main at REPL[27]:5
[28] f(nt::NamedTuple) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:50
[29] f(a) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:54
[30] f(a, b) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:54
[31] f(a, b, c) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:54
⋮
[53] f(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:54
[54] f(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:54
```

That method 28 is the dispatch that requires permutation; it's called for any named tuple without an explicit method.

Now we can benchmark:
```julia
function runbenchmark()
    times = Matrix{Float64}(undef, 26,2)
    for n in 1:26
        fkeys = Tuple(letters[1:n])
        rkeys = reverse(fkeys)
        
        nt = NamedTuple{fkeys}(1:n)
        rnt = NamedTuple{rkeys}(n:-1:1)

        times[n,1] = @belapsed($f($nt))
        times[n,2] = @belapsed($f($rnt))
    end
    return times
end

times = runbenchmark()
```

Here's the result:

![benchmarks](https://user-images.githubusercontent.com/1184449/116616679-d2abef00-a8f1-11eb-9507-0af267fa37cb.png)