using KeywordCalls
using Test

f(nt::NamedTuple{(:c,:b,:a)}) = nt.a^3 + nt.b^2 + nt.c
@kwcall f(c,b,a)

@testset "KeywordCalls.jl" begin
    @test @inferred f(1, 2, 3) == 32
    @test @inferred f(a=1, b=2, c=3) == 8
    @test @inferred f((a=1, b=2, c=3)) == 8
end
