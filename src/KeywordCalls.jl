module KeywordCalls

using Compat

export @kwcall

@generated _sort(nt::NamedTuple{K}) where {K} = :(NamedTuple{($(QuoteNode.(sort(collect(K)))...),)}(nt))

function _call_in_default_order end

# Thanks to @simeonschaub for this implementation 
macro kwcall(ex)
    @assert Meta.isexpr(ex, :call)
    f, args... = ex.args
    f, args, sorted_args = esc(f), QuoteNode.(args), QuoteNode.(sort(args))
    return quote
        KeywordCalls._call_in_default_order(::typeof($f), nt::NamedTuple{($(sorted_args...),)}) = $f(NamedTuple{($(args...),)}(nt))
        $f(nt::NamedTuple) = KeywordCalls._call_in_default_order($f, _sort(nt))
        $f(; kw...) = $f(NamedTuple(kw))
    end
end

end
