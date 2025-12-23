using Documenter
using StanfordAA228V

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
    warnonly = [:doctest]  # Don't fail on doctest errors, just warn
)

# Uncomment below to deploy docs (requires setup)
# deploydocs(
#     repo = "github.com/YOUR_USERNAME/StanfordAA228V.jl.git",
# )
