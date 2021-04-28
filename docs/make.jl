using KeywordCalls
using Documenter

DocMeta.setdocmeta!(KeywordCalls, :DocTestSetup, :(using KeywordCalls); recursive=true)

makedocs(;
    modules=[KeywordCalls],
    authors="Chad Scherrer <chad.scherrer@gmail.com> and contributors",
    repo="https://github.com/cscherrer/KeywordCalls.jl/blob/{commit}{path}#{line}",
    sitename="KeywordCalls.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cscherrer.github.io/KeywordCalls.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/cscherrer/KeywordCalls.jl",
)
