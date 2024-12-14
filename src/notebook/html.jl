start_code() = html"""
<div class='container'><div class='line'></div><span class='text' style='color:#B1040E'><b><code>&lt;START CODE&gt;</code></b></span><div class='line'></div></div>
<p> </p>
<!-- START_CODE -->
"""

end_code() = html"""
<!-- END CODE -->
<p><div class='container'><div class='line'></div><span class='text' style='color:#B1040E'><b><code>&lt;END CODE&gt;</code></b></span><div class='line'></div></div></p>
"""

function combine_html_md(contents::Vector; return_html=true)
    process(str) = str isa HTML ? str.content : html(str)
    html_string = join(map(process, contents))
    return return_html ? HTML(html_string) : html_string
end

wrapdiv(html_or_md; kwargs...) = wrapdiv([html_or_md]; kwargs...)
function wrapdiv(html_or_md::Vector; options="", return_html=true)
    return combine_html_md([HTML("<div $options>"), html_or_md, html"</div>"]; return_html)
end

function highlight(html_or_md; options="")
    return wrapdiv(html_or_md; options="class='highlight'$options")
end

function html_expand(title, content::Markdown.MD)
    return HTML("<details><summary>$title</summary>$(html(content))</details>")
end

function html_expand(title, contents::Vector)
    html_code = combine_html_md(contents; return_html=false)
    return HTML("<details><summary>$title</summary>$html_code</details>")
end

html_space() = html"<br><br><br><br><br><br><br><br><br><br><br><br><br><br>"
html_half_space() = html"<br><br><br><br><br><br><br>"
html_quarter_space() = html"<br><br><br>"
