var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = KeywordCalls","category":"page"},{"location":"#KeywordCalls","page":"Home","title":"KeywordCalls","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for KeywordCalls.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [KeywordCalls]","category":"page"},{"location":"#KeywordCalls.@kwalias-Tuple{Any, Any}","page":"Home","title":"KeywordCalls.@kwalias","text":"@kwalias f [\n    alpha => a\n    beta => b\n]\n\ndeclare that for the function f, we should consider alpha to be an alias for a, and beta to be an alias for b. In a call, the names will be mapped accordingly as a pre-processing step.\n\n\n\n\n\n","category":"macro"},{"location":"#KeywordCalls.@kwcall-Tuple{Any}","page":"Home","title":"KeywordCalls.@kwcall","text":"@kwcall f(b,a,c=0)\n\nDeclares that any call f(::NamedTuple{N}) with sort(N) == (:a,:b,:c) should be dispatched to the method already defined on f(::NamedTuple{(:b,:a,:c)})\n\n\n\n\n\n","category":"macro"},{"location":"#KeywordCalls.@kwstruct-Tuple{Any}","page":"Home","title":"KeywordCalls.@kwstruct","text":"@kwstruct Foo(b,a,c=0)\n\nEquivalent to @kwcall Foo(b,a,c=0) plus a definition\n\nFoo(nt::NamedTuple{(:b, :a, :c), T}) where {T} = Foo{(:b, :a, :c), T}(nt)\n\nNote that this assumes existence of a Foo struct of the form\n\nFoo{N,T} [<: SomeAbstractTypeIfYouLike]\n    someFieldName :: NamedTuple{N,T}\nend\n\n\n\n\n\n","category":"macro"}]
}
