using Git
using Pluto

# Clone or update https://github.com/sisl/AA228VProjects
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

projects = ["project0", "project1", "project2", "project3"]

for project in projects
    notebookfile = joinpath(projectdir, project, project * ".jl")
    session = Pluto.ServerSession()
    notebook = Pluto.SessionActions.open(session, notebookfile; run_async=false)
    # Check all cells succeeded
    @assert all(c -> c.errored == false, values(notebook.cells))
end
