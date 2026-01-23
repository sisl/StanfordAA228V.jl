using Pluto, Pkg, Test

@assert pkgversion(Pkg) >= v"1.13.0" "Pkg 1.13+ required because we rely on https://github.com/JuliaLang/Pkg.jl/pull/4225."
@assert haskey(ENV, "AA228V_PROJECTS_DIR") "AA228V_PROJECTS_DIR must be set"

const PROJECTDIR = ENV["AA228V_PROJECTS_DIR"]
const AA228V_PKGDIR = dirname(dirname(@__FILE__))
const PROJECTS = ["project1", "project2", "project3"]

function run_notebook_test(project)
    notebookfile = joinpath(PROJECTDIR, project, "$project.jl")
    Pluto.activate_notebook_environment(notebookfile)
    Pkg.develop(; name="StanfordAA228V", path=AA228V_PKGDIR)

    session = Pluto.ServerSession()
    notebook = Pluto.SessionActions.open(session, notebookfile; run_async=false)

    result = Pluto.WorkspaceManager.eval_fetch_in_workspace(
        (session, notebook),
        :(all([pass_small, pass_medium, pass_large]))
    )

    Pluto.SessionActions.shutdown(session, notebook; async=false)
    return result
end

@testset "Downstreamtests" begin
    @testset "Project $p" for p in PROJECTS
        @test run_notebook_test(p)
    end
end
