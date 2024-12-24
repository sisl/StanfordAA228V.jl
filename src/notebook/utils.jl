get_filename(::Type{<:Project1SmallSystem}, project_num::Int)  = "project$project_num-small.val"
get_filename(::Type{<:Project1MediumSystem}, project_num::Int) = "project$project_num-medium.val"
get_filename(::Type{<:Project1LargeSystem}, project_num::Int)  = "project$project_num-large.val"
get_filename(sys_type::Type{<:System}, Project::Module)  = get_filename(sys_type, Project.project_num)
get_filename(sys::System, Project::Module)  = get_filename(typeof(sys), Project)
get_filename(sys::System, project_num::Int)  = get_filename(typeof(sys), project_num)

env_name(sys::System) = typeof(sys).types[2].name.name

system_size(sys::Project1SmallSystem) = "Small"
system_size(sys::Project1MediumSystem) = "Medium"
system_size(sys::Project1LargeSystem) = "Large"

system_name(sys::System) = "$(system_size(sys))System"

numdigits(n::Int) = n == 0 ? 1 : floor(Int, log10(abs(n))) + 1


macro conditional_progress(verbose, args...)
    esc(quote
        if $verbose
            @progress $(args...)
        else
            $(args[end])
        end
    end)
end


function expnum(num::Float64; sigdigits=100)
    num = round(num; sigdigits)
    m = match(r"(-*\d\.*\d+)e(-*\d+)", string(num))
    if isnothing(m)
        return num
    else
        lhs = m.captures[1]
        rhs = m.captures[2]
        return "{$lhs}\\mathrm{e}{$rhs}"
    end
end


function format(n::Integer; latex=true)
    s = string(abs(n))
    rev_s = reverse(s)
    chunks = [rev_s[i:min(i+2, end)] for i in 1:3:length(rev_s)]
    chunks = reverse(chunks)
    chunks = [reverse(chunk) for chunk in chunks]
    formatted = join(chunks, latex ? "{,}" : ",")
    return n < 0 ? "-" * formatted : formatted
end
