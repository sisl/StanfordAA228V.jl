module Counted
	export Counter, increment!, reset!, @counted

	# Counter struct to be passed with the @counted counter function...
	Base.@kwdef mutable struct Counter
		count = 0
	end

	# Increment the Counter struct
	function increment!(counter::Counter)
		counter.count += 1
		return counter
	end

	# Reset the Counter struct
	function reset!(counter::Counter)
		counter.count = 0
		return counter
	end

	# Macro to add code to the top of a function that increments the counter
	macro counted(counter, func_def)
	    if func_def.head != :function
	        throw(ArgumentError("@counted is only for function definitions"))
	    end

	    func_name, func_body = func_def.args[1], func_def.args[2]

	    inserted_code = quote
			increment!($(counter))
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
end
