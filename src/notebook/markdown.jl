function info(text; title="Information")
    return Markdown.MD(Markdown.Admonition("info", title, [text]))
end


function hint(text; title="Hint")
    return Markdown.MD(Markdown.Admonition("hint", title, [text]))
end


function almost(text=md"""
    Please modify the `num_failures` function (currently returning `nothing`, which is the default).

    (Please only submit when this is **green**.)
    """)
    return Markdown.MD(Markdown.Admonition("warning", "Warning!", [text]))
end


function keep_working()
    text = md"""
    The answers are not quite right.

    (Please only submit when this is **green**.)
    """
    return Markdown.MD(Markdown.Admonition("danger", "Keep working on it!", [text]))
end


function correct(text=md"""
    All tests have passed, you're done with Project 0!

    Please submit `project0.jl` (this file) to Gradescope.
    """; title="Tests passed!")
    return Markdown.MD(Markdown.Admonition("correct", title, [text]))
end
