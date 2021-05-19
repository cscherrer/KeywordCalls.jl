using KeywordCalls
using Test, Pkg

f(nt::NamedTuple{(:c,:b,:a)}) = nt.a^3 + nt.b^2 + nt.c
@kwcall f(c,b,a)

g(nt::NamedTuple{(:c,:b,:a)}) = f(nt)
@kwcall g(c=0, b, a)

@kwalias f [
    alpha => a
    beta => b
]

@kwalias g [
    alpha => a
    beta => b
]

struct Foo{N,T}
    nt::NamedTuple{N,T}
end

@kwstruct Foo(a,b)

struct Bar{N,T}
    nt::NamedTuple{N,T}
end

@kwstruct Bar(a,b,c=0)

@testset "KeywordCalls.jl" begin
    @testset "Functions" begin
        # @test @inferred f(1, 2, 3) == 32
        @test @inferred f(a=1, b=2, c=3) == 8
        @test @inferred f((a=1, b=2, c=3)) == 8
    end

    @testset "Constructors" begin
        @test @inferred Foo((b=1,a=2)).nt == (a=2,b=1)
    end

    @testset "Functions with defaults" begin
        @test @inferred g(a=1, b=2) == 5
        @test @inferred g((a=1, b=2)) == 5
        @test @inferred g(a=1, b=2, c=3) == 8
        @test @inferred g((a=1, b=2, c=3)) == 8
    end

    @testset "Constructors with defaults" begin
        @test @inferred Bar((b=1,a=2)).nt == (a=2,b=1,c=0)
        @test @inferred Bar((b=1,a=2,c=5)).nt == (a=2,b=1,c=5)
    end

    @testset "Keyword aliases" begin
        @test @inferred f(alpha=1,b=2,c=3) == 8
        @test @inferred g(beta=1, alpha=3) == 28
    end
end

if isfile("./Precompile2/Manifest.toml")
    rm("./Precompile2/Manifest.toml")
end

Pkg.activate("./Precompile2")
Pkg.develop(PackageSpec(path="./Precompile1"))

using Precompile2

@testset "caching with precompilation" begin
    @test Precompile2.test() == (a=2, b=1)
end
