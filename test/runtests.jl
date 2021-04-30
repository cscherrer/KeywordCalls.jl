using KeywordCalls
using Test

f(nt::NamedTuple{(:c,:b,:a)}) = nt.a^3 + nt.b^2 + nt.c
@kwcall f(c,b,a)

struct Foo{N,T}
    nt::NamedTuple{N,T}
end

Foo(nt::NamedTuple{(:a,:b),T}) where {T} = Foo{(:a,:b), T}(nt)

@kwcall Foo(a,b)

@testset "KeywordCalls.jl" begin
    @testset "Functions" begin
        # @test @inferred f(1, 2, 3) == 32
        @test @inferred f(a=1, b=2, c=3) == 8
        @test @inferred f((a=1, b=2, c=3)) == 8
    end

    @testset "Constructors" begin
        @test @inferred Foo((b=1,a=2)).nt == (a=2,b=1)
    end
end
