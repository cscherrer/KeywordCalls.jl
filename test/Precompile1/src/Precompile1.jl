module Precompile1

using KeywordCalls

struct Foo{N,T}
    nt::NamedTuple{N,T}
end

@kwstruct Foo(a,b)

Foo(nt::NamedTuple{(:a,:b), Tuple{A,B}}) where {A,B} = Foo{(:a,:b), Tuple{A,B}}(nt)

export Foo

end # module
