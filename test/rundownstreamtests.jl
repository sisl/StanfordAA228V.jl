using Git
using Pluto
using Pkg
using Test
using TOML

# Clone or update https://github.com/sisl/AA228VProjects
# Note that this is cloned during CI already, so cloning is typically only needed for local testing.
repo_url = "https://github.com/sisl/AA228VProjects.git"
projectdir = get(ENV, "AA228V_PROJECTS_DIR", joinpath(dirname(@__DIR__), "..", "..", "AA228VProjects"))

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

# projects = ["project0", "project1", "project2", "project3"]
projects = ["project1"]
aa228v_pkgdir = (isinteractive() ? pwd() : dirname(dirname(@__FILE__)))
@show aa228v_pkgdir

for project in projects
    notebookfile = joinpath(projectdir, project, project * ".jl")

    @info "Testing $project"
    # Here we must make sure to "dev" the current version of the package.
    # The issue is that if there is any package resolution failure, Pluto
    # deletes the whole Manifest (via GracefulPkg.jl). So adding a custom
    # path to the manifest is fragile. Instead we must add a `[sources]`
    # section to the Project.toml file, which will "survive" a Manifest
    # reset. We must also remove any `compat` entry for our package.

    # Activate the notebook's environment and develop the local package.
    # We sleep briefly after changes to make sure all files can sync.
    Pluto.activate_notebook_environment(notebookfile)
    @info "Removing upstream StanfordAA228V and updating Plots (for compat)."
    withenv("JULIA_PKG_PRECOMPILE_AUTO" => 0) do
        Pkg.rm("StanfordAA228V")  # this removes the compat
        sleep(1)
        # Pkg.update("Plots")  # there's a compat error otherwise
        # sleep(1)
        Pkg.develop(name="StanfordAA228V", path=aa228v_pkgdir)
    end
    sleep(3)
    @info "Adding [sources] section to $(Pkg.project().path)."
    pkgproject = read(Pkg.project().path, String) |> TOML.parse
    pkgproject["sources"] = Dict(
        "StanfordAA228V" => Dict("path" => aa228v_pkgdir)
    )
    let
        open(Pkg.project().path; write=true) do io
            TOML.print(io, pkgproject)
        end
        sleep(0.5)
    end
    sleep(0.5)
    @info "Resolving env."
    Pkg.resolve()
    @info "Instantiating env."
    Pkg.instantiate()

    # check that Manifest is updated correctly
    pkgmanifest = let path = joinpath(dirname(Pkg.project().path), "Manifest.toml")
        TOML.parse(read(path, String))
    end
    @test haskey(pkgmanifest["deps"]["StanfordAA228V"][], "path")
    # @test !haskey(pkgmanifest["deps"]["StanfordAA228V"][], "git-tree-sha1")

    # Open and run the notebook.
    session = Pluto.ServerSession()
    notebook = Pluto.SessionActions.open(session, notebookfile; run_async=false)

    # Check that all cells succeeded.
    @test all(c -> c.errored == false, values(notebook.cells))
    @info "$project completed successfully"

    # Check that custom path is still used after GracefulPkg has done its job.
    pkgmanifest = let path = joinpath(dirname(Pkg.project().path), "Manifest.toml")
        TOML.parse(read(path, String))
    end
    @test haskey(pkgmanifest["deps"]["StanfordAA228V"][], "path")
    # @test !haskey(pkgmanifest["deps"]["StanfordAA228V"][], "git-tree-sha1")
end

# Step 2:
# copy in the answers, e.g. via key that I store in the envvar of the repo and use to decode the answers
# we probably encode the files with `age`
# We can think about using `Argus` to pattern match the cells that we want to delete
