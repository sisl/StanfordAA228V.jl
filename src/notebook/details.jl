function submission_details(bind_directory_trigger, Project, system_types::Vector)
    project_num = Project.project_num
    overleaf_link = Project.overleaf_link
    points_small = Project.points_small
    points_medium = Project.points_medium
    points_large = Project.points_large
    points_writeup_descr = Project.points_writeup_descr
    points_writeup_code = Project.points_writeup_code

    Markdown.MD(HTML("<h2 id='submission'>Submission</h2>"),
	Markdown.parse("""
	You will submit **three** results files (`.val`) to the **`"Project $project_num (.val files)"`** Gradescope assignment and **include the PDF** in your write up in the **"`Project $project_num (write up)`"** Gradescope assignment (see below).
	"""),
	Markdown.parse("""
	1. **Gradescope assignment `"Project $project_num (.val files)"`** (total $(points_small + points_medium + points_large) points):
	    1. `$(get_filename(system_types[1], Project))` ($points_small points)
	    1. `$(get_filename(system_types[2], Project))` ($points_medium points)
	    1. `$(get_filename(system_types[3], Project))` ($points_large points)
	1. **Gradescope assignment `"Project $project_num (write up)"`** (total $(points_writeup_descr + points_writeup_code) points):
	    - Description of algorithms ($points_writeup_descr points)
	    - PDF of Pluto notebook ($points_writeup_code points)


	_The_ `.val` _files will be automatically saved for you in the same directory as this notebook:_
	"""),
	md"""
	- $(bind_directory_trigger)
	    - ↑ Click to open directory.
	""",
	Markdown.parse("""
	**Note**: You do _not_ have to submit the `project$project_num.jl` file.

	### Algorithm write up
	Include a PDF write up describing the algorithms you used to solve the three problems. Include the notebook PDF. This should not be more than 1 to 2 pages (excluding the PDF of the notebook code).

	**You'll submit this in a separate Gradescope assignment named `"Project $project_num (Write Up)"`.**

	### Export to PDF
	After you're finished coding, please export this notebook to PDF.
	- Click the `[↑]` icon in the top right and click "PDF", then "Print to PDF".

	Include the **`project$project_num.pdf`** in your write-up:
	-  \$\\LaTeX\$ Overleaf template: [`$overleaf_link`]($overleaf_link)
	    - **Note**: You do _not_ have to use the template or \$\\LaTeX\$.

	If you encounter issues, [please ask us on Ed](https://edstem.org/us/courses/69226/discussion).
	"""))
end


function textbook_details(chapters=[])
    Markdown.parse("""
    ## Textbook
    [![textbook](https://img.shields.io/badge/textbook-MIT%20Press-0072B2.svg)](https://algorithmsbook.com/validation/files/val.pdf)
    [![coverart](https://raw.githubusercontent.com/sisl/AA228VProjects/refs/heads/main/media/coverart.svg)](https://algorithmsbook.com/validation/files/val.pdf)
    You may find the _Algorithms for Validation_ textbook helpful, specifically the following chapters:
    $(join(map(ch->"- $ch", chapters), "\n"))
    """)
end


function baseline_details(sys::System; n_baseline, descr=md"**TODO**", max_steps::Function)
	d = get_depth(sys)
	n = max_steps(sys)
	n_formatted = format(n; latex=true)
	n_baseline_formatted = format(n_baseline; latex=true)
	m_baseline_formatted = format(n_baseline ÷ d; latex=true)

	return Markdown.parse("""
	## Baseline: $(system_size(sys))
	The $descr baseline was run with a rollout depth of \$d=$d\$ and \$m=$m_baseline_formatted\$ number of rollouts, for a total number of steps \$n = m \\times d = $(n_baseline_formatted)\$.

	**Note**: Here we increase \$n\$ to \$$(n_baseline_formatted)\$ because the random baseline needs more steps to find failures.

	> **Your algorithm should find likely failures more efficiently than than the baseline.**
	>
	> _This doesn't mean your likelihood needs to be better, as the baseline is given more steps to run. This just means you have to find failures more efficiently._
	>
	> **You'll be given fewer steps of \$n = $n_formatted\$.**
	""")
end

function depth_highlight(sys::System)
	highlight(Markdown.parse("""**Note**: One rollout of the `$(system_name(sys))` has a fixed length of \$d=$(get_depth(sys))\$ (use `get_depth`)."""))
end
