module Counted
	export @counted, @tracked, stepcount

	# Allows the closure to replace these template functions.
	module Inner
		function stepcount end
		function increment! end
		function reset! end
	end

	using .Inner

	# Create a closure that captures a local variable.
	let counter = Ref(0)
		function Inner.increment!()
			counter[] += 1
			return nothing
		end

		Inner.stepcount() = counter[]

		function Inner.reset!()
			counter[] = 0
			return nothing
		end
	end

	stepcount = Inner.stepcount
	increment! = Inner.increment!
	reset! = Inner.reset!

	macro tracked(func_def)
		if func_def.head != :function
			throw(ArgumentError("@tracked is only for function definitions"))
		end

		func_name, func_body = func_def.args[1], func_def.args[2]

		inserted_code = quote
			Counted.reset!()
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

	# Macro to add code to the top of a function that increments the counter
	macro counted(func_def)
		if func_def.head != :function
			throw(ArgumentError("@counted is only for function definitions"))
		end

		func_name, func_body = func_def.args[1], func_def.args[2]

		inserted_code = quote
			Counted.increment!()
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
