module KeywordCalls

export @kwcall

@generated _sort(nt::NamedTuple{K}) where {K} = :(NamedTuple{($(QuoteNode.(sort(collect(K)))...),)}(nt))

macro kwcall(ex)
    f, args... = ex.args
    f, args, sorted_args = esc(f), QuoteNode.(args), QuoteNode.(sort(args))
    _call_in_default_order = GlobalRef(KeywordCalls, :_call_in_default_order)
    return quote
        $_call_in_default_order($f, nt::NamedTuple{($(sorted_args...),)}) = $f(NamedTuple{($(args...),)}(nt))
        $f(nt::NamedTuple) = $_call_in_default_order($f, _sort(nt))
        $f(; kw...) = $f(NamedTuple(kw))
    end
end

end
