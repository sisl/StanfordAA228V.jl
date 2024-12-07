module Counted
	export @counted, @tracked, stepcount, @small, @medium, @large

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

	macro define_macro(macro_name::Symbol)
		macro_name_str = string(macro_name)
		quote
			macro $(esc(macro_name))(func_def)
				local name_str = $(macro_name_str)
	
				if func_def.head != :function
					throw(ArgumentError("@$(macro_name) is only for function definitions"))
				end
	
				# Extract the function name and body
				func_name, func_body = func_def.args[1], func_def.args[2]
	
				# Code to insert at the start of the function
				inserted_code = quote
					Counted.reset!()
				end
	
				if func_body.head == :block
					new_body = Expr(:block, inserted_code, func_body.args...)
				else
					new_body = Expr(:block, inserted_code, func_body)
				end
	
				# The original function
				old_func_def = Expr(:function, func_name, new_body)
	
				# Create the transformed function name with the given suffix
				new_func_name = deepcopy(func_name)
				new_func_name.args[1] = Symbol(new_func_name.args[1], :_, name_str)
				new_func_def = Expr(:function, new_func_name, new_body)
	
				# Return both definitions
				return esc(quote
					$new_func_def
					$old_func_def
				end)
			end
		end
	end

	@define_macro small
	@define_macro medium
	@define_macro large
end
