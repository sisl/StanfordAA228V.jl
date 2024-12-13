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
    return join(map(process, contents))
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
