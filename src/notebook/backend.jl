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
end

module Project2
backend = joinpath(@__DIR__, ".project1") # TODO.
project_num = 2
overleaf_link = "https://www.overleaf.com/read/sxwmykbjftrm#538c53"
points_small = 1
points_medium = 2
points_large = 3
points_writeup_descr = 3
points_writeup_code = 2
@assert points_small + points_medium + points_large + points_writeup_descr + points_writeup_code == 11
end

tempmodule(prefix="UsingThisViolatesTheHonorCode") = string(prefix, "_", basename(tempname()))
process(n, t=tempname(), c=base64decode(read(n, String))) = [begin open(t, "w+") do f; write(f, c); end end, t][end]
macro include(filename); return esc(quote; t = process($filename); include(t); rm(t, force=true); nothing end) end

function protected_module(TempModuleName, ModuleName, inner_code::String)
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
					@eval using \$(Symbol(mod))
				catch err
					if err isa ArgumentError
						try
							@eval using StanfordAA228V.\$(Symbol(mod))
						catch err2
							@warn err2
						end
					else
						@warn err
					end
				end
			end

			$inner_code
		end
	"""
end

macro load(filename, prefix="UsingThisViolatesTheHonorCode")
    return esc(quote
        let
            local fn
            processed = false
            try
                fn = process($filename)
                processed = true
            catch err
                @warn err
                fn = $filename
            end
            path = string("include(\"", replace(fn, "\\"=>"/"), "\")")
            TempName = tempmodule($prefix)
            eval(Meta.parse(protected_module(TempName, $prefix, path)))
            Mod = getfield(@__MODULE__, Symbol(TempName))
            processed && rm(fn, force=true)
            Mod
        end
    end)
end
