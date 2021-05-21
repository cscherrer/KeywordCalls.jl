# KeywordCalls

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cscherrer.github.io/KeywordCalls.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cscherrer.github.io/KeywordCalls.jl/dev)
[![Build Status](https://github.com/cscherrer/KeywordCalls.jl/workflows/CI/badge.svg)](https://github.com/cscherrer/KeywordCalls.jl/actions)
[![Coverage](https://codecov.io/gh/cscherrer/KeywordCalls.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/cscherrer/KeywordCalls.jl)


In Julia, the named tuples `(a=1, b=2)` and `(b=2, a=1)` are distinct. In some cases, it's convenient to define a method for each _set_ of names, rather than each particular ordering. 

KeywordCalls.jl lets us do this, and allows specification of a "preferred ordering" for each set of arguments.

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



## Limitations

KeywordCalls tries to push as much of the work as possible to the compiler, to make repeated run-time calls fast. But there's no free lunch, you either pay now or pay later.

If you'd rather avoid the compilation time (at the cost of some runtime overhead), you might try [KeywordDispatch.jl](https://github.com/simonbyrne/KeywordDispatch.jl).

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
# 28 methods for generic function "f":
[1] f(; kwargs...) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:52
[2] f(nt::NamedTuple{(:a, :b, :c, :d, :e, :f, :g), T} where T<:Tuple) in Main at REPL[3]:5
[3] f(nt::NamedTuple{(:a, :b, :c, :d, :e, :f), T} where T<:Tuple) in Main at REPL[3]:5
[4] f(nt::NamedTuple{(:a, :b, :c, :d, :e), T} where T<:Tuple) in Main at REPL[3]:5
[5] f(nt::NamedTuple{(:a, :b, :c, :d), T} where T<:Tuple) in Main at REPL[3]:5
[6] f(nt::NamedTuple{(:a, :b, :c), T} where T<:Tuple) in Main at REPL[3]:5
[7] f(nt::NamedTuple{(:a, :b), T} where T<:Tuple) in Main at REPL[3]:5
[8] f(nt::NamedTuple{(:a,), T} where T<:Tuple) in Main at REPL[3]:5
[9] f(nt::NamedTuple{(:a, :b, :c, :d, :e, :f, :g, :h), T} where T<:Tuple) in Main at REPL[3]:5
[10] f(nt::NamedTuple{(:a, :b, :c, :d, :e, :f, :g, :h, :i), T} where T<:Tuple) in Main at REPL[3]:5
⋮
[26] f(nt::NamedTuple{(:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t, :u, :v, :w, :x, :y), T} where T<:Tuple) in Main at REPL[3]:5
[27] f(nt::NamedTuple{(:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t, :u, :v, :w, :x, :y, :z), T} where T<:Tuple) in Main at REPL[3]:5
[28] f(nt::NamedTuple) in Main at /home/chad/git/KeywordCalls/src/KeywordCalls.jl:50
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
