using Git
using Pluto
using Test
using TOML

# --- Helper functions for editing Pluto notebook embedded TOML ---

"""
Extract the content of a PLUTO_*_TOML_CONTENTS variable from a notebook string.
Returns (content, start_idx, end_idx) where indices span the entire assignment.
"""
function extract_pluto_toml(notebook::AbstractString, varname::AbstractString)
    # Match: VARNAME = \"""...\"""
    pattern = Regex("($varname\\s*=\\s*\"\"\"\n)(.*?)(\n\"\"\")", "s")
    m = match(pattern, notebook)
    isnothing(m) && error("Could not find $varname in notebook")
    return (m.captures[2], m.offset, m.offset + length(m.match) - 1)
end

"""
Replace a PLUTO_*_TOML_CONTENTS variable in the notebook with new TOML content.
"""
function replace_pluto_toml(notebook::AbstractString, varname::AbstractString, new_content::AbstractString)
    content, start_idx, end_idx = extract_pluto_toml(notebook, varname)
    prefix = "$varname = \"\"\"\n"
    suffix = "\n\"\"\""
    return notebook[1:start_idx-1] * prefix * new_content * suffix * notebook[end_idx+1:end]
end

"""
Modify the embedded Project.toml: remove StanfordAA228V compat, add sources section.
"""
function patch_project_toml(toml_content::AbstractString, pkg_path::AbstractString)
    proj = TOML.parse(toml_content)
    if haskey(proj, "compat")
        delete!(proj["compat"], "StanfordAA228V")
    end
    proj["sources"] = Dict("StanfordAA228V" => Dict("path" => pkg_path))
    return sprint(TOML.print, proj)
end

"""
Modify the embedded Manifest.toml: remove the StanfordAA228V entry.
"""
function patch_manifest_toml(toml_content::AbstractString)
    manifest = TOML.parse(toml_content)
    if haskey(manifest, "deps")
        delete!(manifest["deps"], "StanfordAA228V")
    end
    return sprint(TOML.print, manifest)
end

"""
Patch a Pluto notebook file to use a local path for StanfordAA228V.
"""
function patch_notebook!(notebookfile::AbstractString, pkg_path::AbstractString)
    notebook = read(notebookfile, String)

    # Patch Project.toml
    proj_content, _, _ = extract_pluto_toml(notebook, "PLUTO_PROJECT_TOML_CONTENTS")
    new_proj = patch_project_toml(proj_content, pkg_path)
    notebook = replace_pluto_toml(notebook, "PLUTO_PROJECT_TOML_CONTENTS", new_proj)

    # Patch Manifest.toml
    manifest_content, _, _ = extract_pluto_toml(notebook, "PLUTO_MANIFEST_TOML_CONTENTS")
    new_manifest = patch_manifest_toml(manifest_content)
    notebook = replace_pluto_toml(notebook, "PLUTO_MANIFEST_TOML_CONTENTS", new_manifest)

    write(notebookfile, notebook)
    @info "Patched $notebookfile to use local StanfordAA228V at $pkg_path"
end

# --- Clone AA228VProjects and run tests ---

repo_url = get(ENV, "AA228V_PROJECTS_URL", "https://github.com/sisl/AA228VProjects.git")
projects_ref = get(ENV, "AA228V_PROJECTS_REF", "main")
aa228v_pkgdir = isinteractive() ? pwd() : dirname(dirname(@__FILE__))

function run_notebook_tests(projectdir)
    notebookfiles = [joinpath(projectdir, "project$i", "project$i.jl") for i in 1:3]

    @testset "Project $i" for (i, notebookfile) in zip(1:3, notebookfiles)
        @info "Testing project $i: $notebookfile"

        patch_notebook!(notebookfile, aa228v_pkgdir)

        session = Pluto.ServerSession()
        notebook = Pluto.SessionActions.open(session, notebookfile; run_async=false)

        @test all(c -> !c.errored, values(notebook.cells))
        # @test Pluto.WorkspaceManager.eval_fetch_in_workspace((session, notebook), :(pass_small))
        # @test Pluto.WorkspaceManager.eval_fetch_in_workspace((session, notebook), :(pass_medium))
        # @test Pluto.WorkspaceManager.eval_fetch_in_workspace((session, notebook), :(pass_large))

        @info "Project $i passed. Shutting down session."
        Pluto.SessionActions.shutdown(session, notebook; async=false)
    end
end

if haskey(ENV, "AA228V_PROJECTS_DIR")
    # Use existing directory (for local development)
    projectdir = ENV["AA228V_PROJECTS_DIR"]
    @info "Using existing project directory: $projectdir"
    cd(projectdir) do
        run(`$(git()) fetch --all`)
        run(`$(git()) switch --force --detach $projects_ref`)
        run(`$(git()) clean -fd`)
    end
    run_notebook_tests(projectdir)
else
    # Clone to tempdir (auto-cleanup)
    mktempdir() do projectdir
        @info "Cloning $repo_url to $projectdir (branch: $projects_ref)"
        run(`$(git()) clone --branch $projects_ref $repo_url $projectdir`)
        run_notebook_tests(projectdir)
    end
end
