global step_counter = Counter()

function Counted.reset!()
    global step_counter
    reset!(step_counter)
end

macro tracked(func_def)
    if func_def.head != :function
        throw(ArgumentError("@tracked is only for function definitions"))
    end

    func_name, func_body = func_def.args[1], func_def.args[2]

    inserted_code = quote
        reset!($(step_counter))
    end

    if func_body.head == :block
        # If the body is a block
        new_body = Expr(:block, inserted_code, func_body.args...)
    else
        # If the body is a single expression
        new_body = Expr(:block, inserted_code, func_body)
    end

    new_func_def = Expr(:function, func_name, new_body)

    return esc(new_func_def)
end
