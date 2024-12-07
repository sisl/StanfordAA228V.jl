module Counted
	export @counted, @tracked, stepcount, @small, @medium, @large, InvalidSeeders, check_stacktrace_for_invalids

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

	########################################
	# Seeding control:
	# Restrict access to changing RNG seed
	# in @define_macro generated functions.
	########################################

	module InvalidSeeders
		module InnerInvalidSeeders
			function invalids end
			function add! end
			function reset! end
		end

		using .InnerInvalidSeeders

		let fnames = Ref(Symbol[])
			InnerInvalidSeeders.invalids() = fnames[]

			function InnerInvalidSeeders.add!(sym::Symbol)
				if !(sym in fnames[])
					push!(fnames[], sym)
				end
				return fnames[]
			end

			function InnerInvalidSeeders.reset!()
				fnames[] = Symbol[]
				return nothing
			end
		end

		invalids = InnerInvalidSeeders.invalids
		add! = InnerInvalidSeeders.add!
		reset! = InnerInvalidSeeders.reset!
	end

	using .InvalidSeeders

	function check_stacktrace_for_invalids(invalid_functions::Vector{Symbol})
		st = stacktrace()
		for frame in st
			if frame.func in invalid_functions
				error("Please do not set the RNG seed within function $(frame.func)")
			end
		end
		return nothing
	end

	#=
	# Include this code block in the notebook (or encoded code)
	using Random

	function Random.seed!(seed=nothing)
		check_stacktrace_for_invalids(InvalidSeeders.invalids())
		Random.seed!(Random.default_rng(), seed)
		copy!(Random.get_tls_seed(), Random.default_rng())
		Random.default_rng()
	end
	=#

	macro define_macro(macro_name::Symbol)
		macro_name_str = string(macro_name)
		quote
			macro $(esc(macro_name))(func_def)
				local name_str = $(macro_name_str)

				if func_def.head != :function
					throw(ArgumentError("@$(macro_name) is only for function definitions"))
				end

				# Extract the function name and body
				func_sig, func_body = func_def.args[1], func_def.args[2]
				func_name = func_sig.args[1]
				new_func_sig = deepcopy(func_sig)
				new_func_name = Symbol(new_func_sig.args[1], :_, name_str)

				# Add generated function name to invalid seed changers
				for sym in [func_name, new_func_name]
					InvalidSeeders.add!(sym)
				end

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
				old_func_def = Expr(:function, func_sig, new_body)

				# Create the transformed function name with the given suffix
				new_func_sig.args[1] = new_func_name
				new_func_def = Expr(:function, new_func_sig, new_body)

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
