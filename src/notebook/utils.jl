function expnum(num::Float64; sigdigits=3)
    num = round(num; sigdigits)
    m = match(r"(\d\.*\d+)e(-*\d+)", string(num))
    if isnothing(m)
        return num
    else
        lhs = m.captures[1]
        rhs = m.captures[2]
        return "{$lhs}\\mathrm{e}{$rhs}"
    end
end


function format(n::Integer; latex=false)
    s = string(abs(n))
    rev_s = reverse(s)
    chunks = [rev_s[i:min(i+2, end)] for i in 1:3:length(rev_s)]
    chunks = reverse(chunks)
    chunks = [reverse(chunk) for chunk in chunks]
    formatted = join(chunks, latex ? "{,}" : ",")
    return n < 0 ? "-" * formatted : formatted
end
