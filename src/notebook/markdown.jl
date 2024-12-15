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

# Modified from PlutoTeachingTools.jl:
# https://github.com/JuliaPluto/PlutoTeachingTools.jl/blob/c6facca8e7b233f0ba477921281f4a2727a0a070/src/present.jl#L36
function Columns(cols...; 
				 widths=nothing,
				 gap=2,
				 styles=fill(Dict(), length(cols)),
				 style=Dict(), Div) # TODO: Div
    ncols = length(cols)
    ngaps = ncols - 1
    if isnothing(widths)
        widths = fill(100 / ncols, ncols)
    end
    if gap > 0 # adjust widths if gaps are desired
        widths = widths / sum(widths) * (sum(widths) - gap * ngaps)
    end

	function merge_styles(d, i)
		if length(styles) ≥ i
			return merge(d, styles[i])
		else
			return d
		end
	end

    columns = [
        Div([cols[i]], style=merge_styles(Dict("flex" => "0 1 $(widths[i])%"), i)) for
        i in 1:ncols
    ]
   the_gap = Div([], style=Dict("flex" => "0 0 $gap%"))

    # insert gaps between columns
    # i.e. [a, b, c] ==> [a, gap, b, gap, c]
    children = vec([reshape(columns, 1, :); fill(the_gap, 1, ncols)])[1:(end - 1)]

	# "text-align"=>"center",
    return Div(children, style=merge(Dict(
        "display" => "flex",
        "flex-direction" => "row",
        "padding-top" => "10px",
        "padding-bottom" => "10px",
        "text-align" => "center",
    ), style))
end