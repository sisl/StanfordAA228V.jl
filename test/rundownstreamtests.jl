using Git
using Pluto

# Clone or update https://github.com/sisl/AA228VProjects
# Note that this is cloned during CI already, so cloning is typically only needed for local testing.
repo_url = "https://github.com/sisl/AA228VProjects.git"
projectdir = joinpath(@__DIR__, "AA228VProjects")

# Clone repo if it doesn't exist, otherwise pull latest
if !isdir(projectdir)
    @info "Cloning $repo_url to $projectdir"
    run(`$(git()) clone $repo_url $projectdir`)
else
    @info "Updating $projectdir (discarding any local changes)"
    cd(projectdir) do
        run(`$(git()) fetch origin`)
        run(`$(git()) switch --force --detach origin/main`)
        run(`$(git()) clean -fd`)
    end
end

function inject_dev_package(notebook_path, package_name, package_path)
    content = read(notebook_path, String)
    
    # Extract Project.toml (first special cell)
    proj_regex = r"# ╔═╡ 00000000-0000-0000-0000-000000000001\nTOML.*?\"\"\"(.*?)\"\"\""s
    proj_match = match(proj_regex, content)
    
    # Extract Manifest.toml (second special cell)
    manifest_regex = r"# ╔═╡ 00000000-0000-0000-0000-000000000002\nTOML.*?\"\"\"(.*?)\"\"\""s
    manifest_match = match(manifest_regex, content)
    
    # Modify Project.toml
    project = TOML.parse(proj_match[1])
    
    # Remove compat constraint
    if haskey(project, "compat") && haskey(project["compat"], package_name)
        delete!(project["compat"], package_name)
    end
    
    # Add/update sources section
    if !haskey(project, "sources")
        project["sources"] = Dict{String, Any}()
    end
    project["sources"][package_name] = Dict("path" => package_path)
    
    # Modify Manifest.toml
    manifest = TOML.parse(manifest_match[1])
    
    # Find and modify the package entry in manifest
    if haskey(manifest, "deps") && haskey(manifest["deps"], package_name)
        entries = manifest["deps"][package_name]
        # Handle both single entry and array of entries
        if entries isa AbstractVector
            for entry in entries
                delete!(entry, "version")
                delete!(entry, "git-tree-sha1")
                entry["path"] = package_path
            end
        else
            delete!(entries, "version")
            delete!(entries, "git-tree-sha1")
            entries["path"] = package_path
        end
    end
    
    # Convert back to TOML strings
    new_proj = sprint(TOML.print, project)
    new_manifest = sprint(TOML.print, manifest)
    
    # Replace in content
    content = replace(content, proj_match[1] => new_proj, count=1)
    content = replace(content, manifest_match[1] => new_manifest, count=1)
    
    # Write back
    write(notebook_path, content)
    @info "Injected dev package $package_name at $package_path into $notebook_path"
end

projects = ["project0", "project1", "project2", "project3"]
package_path = abspath(@__DIR__)  # Full path to StanfordAA228V package

for project in projects
    notebookfile = joinpath(projectdir, project, project * ".jl")
    session = Pluto.ServerSession()
    notebook = Pluto.SessionActions.open(session, notebookfile; run_async=false)
    # Check all cells succeeded
    @assert all(c -> c.errored == false, values(notebook.cells))
end
