module Project1
    backend = joinpath(@__DIR__, ".project1")
    project_num = 1
    overleaf_link = "https://www.overleaf.com/read/vbdvkhptvngj#9c2461"
    points_small = 1
    points_medium = 2
    points_large = 3
    points_writeup_descr = 3
    points_writeup_code = 2
    @assert points_small + points_medium + points_large + points_writeup_descr + points_writeup_code == 11
end # Project1


module Project2
    backend = joinpath(@__DIR__, ".project2")
    project_num = 2
    overleaf_link = "https://www.overleaf.com/read/sxwmykbjftrm#538c53"
    points_small = 1
    points_medium = 2
    points_large = 3
    points_writeup_descr = 3
    points_writeup_code = 2
    @assert points_small + points_medium + points_large + points_writeup_descr + points_writeup_code == 11
end # Project2


module Project3
    backend = joinpath(@__DIR__, ".project3")
    project_num = 3
    overleaf_link = "https://www.overleaf.com/read/frpcjyzmvvdv#421318"
    points_small = 1
    points_medium = 2
    points_large = 3
    points_writeup_descr = 3
    points_writeup_code = 2
    @assert points_small + points_medium + points_large + points_writeup_descr + points_writeup_code == 11
end # Project3


tempmodule(prefix="UsingThisViolatesTheHonorCode") = string(prefix, "_", basename(tempname()))
process(fn, t=tempname(), k=Int((typemax(UInt16)+1)^(1/8))) = [[begin fn = let c = base64decode(read(fn, String)); open(t, "w+") do f; write(f, c); end; t; end; end for _ ∈ 1:k], t][end]
macro include(filename); return esc(quote; t = process($filename); include(t); rm(t, force=true); nothing end) end
macro load(filename, prefix="UsingThisViolatesTheHonorCode")
    return esc(quote; let; local fn; processed = false; try; fn = process($filename); processed = true; catch err; @warn(err); fn = $filename; end; path = string("include(\"", replace(fn, "\\"=>"/"), "\")"); TempName = tempmodule($prefix); eval(Meta.parse(protected_module(TempName, $prefix, path))); Mod = getfield(@__MODULE__, Symbol(TempName)); (processed && rm(fn, force=true)); Mod; end; end)
end
function protected_module(TempModuleName, ModuleName, inner_code::String; BackendModule="StanfordAA228V")
    return """
        module $TempModuleName
            ThisModule = split(string(@__MODULE__), ".")[end]

            # Load all code and packages from parent module
            Parent = parentmodule(@__MODULE__)

            modules(m::Module) = ccall(:jl_module_usings, Any, (Any,), m)

            # Load functions and variables
            for name in names(Parent, imported=true)
                if name != Symbol(ThisModule) && !occursin("#", string(name)) && !occursin("$ModuleName", string(name))
                    @eval const \$(name) = \$(Parent).\$(name)
                end
            end

            excludes = ["PlutoRunner", "InteractiveUtils", "Core", "Base", "Base.MainInclude"]

            # Load packages
            for mod in modules(Parent)
                string(mod) in excludes && continue
                try
                    eval(Meta.parse("using \$mod"))
                catch err
                    @warn err
                end
            end

            $inner_code
        end
    """
end
