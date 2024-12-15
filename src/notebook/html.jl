function notebook_style()
    html"""
    <style>
        h3 {
            border-bottom: 1px dotted var(--rule-color);
        }

        summary {
            font-weight: 500;
            font-style: italic;
        }

        .container {
            display: flex;
            align-items: center;
            width: 100%;
            margin: 1px 0;
            border: 2px solid #B83A4B;
            background-color: #B83A4B22;
        }

        .container span b code {
            background-color: unset;
        }

        .line {
            flex: 1;
            height: 2px;
            /* background-color: #B83A4B; */
            background-color: unset;
        }

        .text {
            margin: 5px 5px;
            white-space: nowrap; /* Prevents text from wrapping */
            color: var(--cursor-color);
        }

        h2hide {
            border-bottom: 2px dotted var(--rule-color);
            font-size: 1.8rem;
            font-weight: 700;
            margin-bottom: 0.5rem;
            margin-block-start: calc(2rem - var(--pluto-cell-spacing));
            font-feature-settings: "lnum", "pnum";
            color: var(--pluto-output-h-color);
            font-family: Vollkorn, Palatino, Georgia, serif;
            line-height: 1.25em;
            margin-block-end: 0;
            display: block;
            margin-inline-start: 0px;
            margin-inline-end: 0px;
            unicode-bidi: isolate;
        }

        h3hide {
            border-bottom: 1px dotted var(--rule-color);
            font-size: 1.6rem;
            font-weight: 600;
            color: var(--pluto-output-h-color);
            font-feature-settings: "lnum", "pnum";
            font-family: Vollkorn, Palatino, Georgia, serif;
            line-height: 1.25em;
            margin-block-start: 0;
            margin-block-end: 0;
            display: block;
            margin-inline-start: 0px;
            margin-inline-end: 0px;
            unicode-bidi: isolate;
        }

        .checkbox-label {
            font-feature-settings: "lnum", "pnum";
            color: var(--pluto-output-h-color);
            font-family: Vollkorn, Palatino, Georgia, serif;
            font-size: 1.4rem;
            font-weight: 600;
            line-height: 1.25em;
            /* border-top: 2px dotted var(--rule-color); */
            /* border-bottom: 2px dotted var(--rule-color); */
            /* padding-top: 0.5rem; */
            padding-bottom: 0.5rem;
            /* margin-bottom: 0.5rem; */
            /* margin-block-start: calc(2rem - var(--pluto-cell-spacing)); */
            /* margin-block-end: calc(1.5rem - var(--pluto-cell-spacing)); */
            display: inline-block;
            margin-inline-start: 0px;
            margin-inline-end: 0px;
        }

        .checkbox-input {
            transform: scale(1.5);
        }

        .styled-button {
            background-color: var(--pluto-output-color);
            color: var(--pluto-output-bg-color);
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-family: Alegreya Sans, Trebuchet MS, sans-serif;
        }

        .highlight {
            background-color: #f0f8ff;
            padding: 10px;
            margin: 30px;
            border: 2px solid #add8e6;
        }

        @media (prefers-color-scheme: dark) {
            .highlight {
                color: #ffffff;
                background-color: #175E54;
                padding: 10px;
                margin: 30px;
                border: 2px solid #6FA287;
            }
        }

        pluto-progress-bar-container {
            flex: 0 1 100% !important; /* full width progress bars */
        }

        .centered {
            display: flex;
            justify-content: center;
        }
    </style>

    <script>
    const buttons = document.querySelectorAll('input[type="button"]');
    buttons.forEach(button => button.classList.add('styled-button'));
    </script>"""
end

function button_style(args...)
    html"""
	<style>
	.styled-button {
			background-color: var(--pluto-output-color);
			color: var(--pluto-output-bg-color);
			border: none;
			padding: 10px 20px;
			border-radius: 5px;
			cursor: pointer;
			font-family: Alegreya Sans, Trebuchet MS, sans-serif;
		}
	</style>

	<script>
	const buttons = document.querySelectorAll('input[type="button"]');
	buttons.forEach(button => button.classList.add('styled-button'));
	</script>"""
end

start_code() = html"""
<div class='container'><div class='line'></div><span class='text'><b><code>&lt;START CODE&gt;</code></b></span><div class='line'></div></div>
<p> </p>
<!-- START_CODE -->
"""

end_code() = html"""
<!-- END CODE -->
<p><div class='container'><div class='line'></div><span class='text'><b><code>&lt;END CODE&gt;</code></b></span><div class='line'></div></div></p>
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
