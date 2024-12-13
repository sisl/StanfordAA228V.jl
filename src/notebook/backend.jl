module Project1
backend = joinpath(@__DIR__, ".project1")
project_num = 1
overleaf_link = "https://www.overleaf.com/read/vbdvkhptvngj#9c2461"
points_small = 2
points_medium = 2
points_large = 2
end

module Project2
backend = joinpath(@__DIR__, ".project2")
end

tmpmodule(prefix="UsingThisViolatesTheHonorCode") = string(prefix, "_", basename(tempname()))
process(n, t=tempname(), c=base64decode(read(n, String))) = [begin open(t, "w+") do f; write(f, c); end end, t][end]
macro include(filename); return esc(quote; t = process($filename); include(t); rm(t, force=true); nothing end) end
