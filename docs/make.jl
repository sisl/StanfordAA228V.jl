using Documenter
using DocumenterCitations
using DocumenterInterLinks
using StanfordAA228V

bib = CitationBibliography(joinpath(@__DIR__, "src", "refs.bib"))

links = InterLinks(
    "Distributions" => "https://juliastats.org/Distributions.jl/stable/"
)

makedocs(
    sitename = "StanfordAA228V.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [StanfordAA228V],
    pages = [
        "Home" => "index.md",
    ],
    doctest = true,  # Enable doctests
    warnonly = [:doctest],  # Don't fail on doctest errors, just warn
    plugins = [bib, links]
)

# Uncomment below to deploy docs (requires setup)
# deploydocs(
#     repo = "github.com/YOUR_USERNAME/StanfordAA228V.jl.git",
# )
