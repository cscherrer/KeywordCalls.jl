using KeywordCalls, BenchmarkTools

letters = Symbol.('a':'z')

for n in 1:26
    fkeys = Tuple(letters[1:n])
    rkeys = reverse(fkeys)

    @eval begin
        f(nt::NamedTuple{$fkeys}) = sum(values(nt))
        $(KeywordCalls._kwcall(:(f($(fkeys...)))))
    end
end

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

using Plots

plt = plot(times[:,1] .* 1e9, legend=:topleft, label="Preferred order", dpi=200)
plot!(plt, times[:,2] .* 1e9, label="Reverse order")
xlabel!(plt, "Number of keys")
ylabel!(plt, "Time (ns)")
