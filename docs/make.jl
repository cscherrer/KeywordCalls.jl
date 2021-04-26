using KeywordOrdering
using Documenter

DocMeta.setdocmeta!(KeywordOrdering, :DocTestSetup, :(using KeywordOrdering); recursive=true)

makedocs(;
    modules=[KeywordOrdering],
    authors="Chad Scherrer <chad.scherrer@gmail.com> and contributors",
    repo="https://github.com/cscherrer/KeywordOrdering.jl/blob/{commit}{path}#{line}",
    sitename="KeywordOrdering.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cscherrer.github.io/KeywordOrdering.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/cscherrer/KeywordOrdering.jl",
)
