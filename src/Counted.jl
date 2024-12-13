module Counted
    export @counted, @tracked, stepcount, @small, @medium, @large, InvalidSeeders, check_stacktrace_for_invalids, check_method_extension

    function get_exported_functions(mod::Module; excludes=[:step])
        exported_names = names(mod)
        return [name for name in exported_names if isdefined(mod, name) && isa(getfield(mod, name), Function) && !(name in excludes)]
    end

    check_method_extension(ThisModule::Module, ExtendedModule::Module, fname::Function) = check_method_extension(ThisModule, ExtendedModule, Symbol(fname))
    check_method_extension(ThisModule::Module, ExtendedModule::Symbol, fname::Union{Function,Symbol}) = check_method_extension(ThisModule, getfield(ThisModule, ExtendedModule), fname)
    function check_method_extension(ThisModule::Module, ExtendedModule::Module, fname::Symbol)
        if getfield(ThisModule, fname) != getfield(ExtendedModule, fname)
            error("""
            Method redefinition error.

            Looks like you're trying to define a custom `$fname` function.
            Please use the Julia dot notation to do so:
             
            function $(string(ExtendedModule)).$(string(fname))(your_inputs)
                # your code
            end
            """)
        end
    end

    check_method_extension(ThisModule::Module, ExtendedModule::String) = check_method_extension(ThisModule, Symbol(ExtendedModule))
    check_method_extension(ThisModule::Module, ExtendedModule::Symbol) = check_method_extension(ThisModule, getfield(ThisModule, ExtendedModule))
    function check_method_extension(ThisModule::Module, ExtendedModule::Module)
        for exported in get_exported_functions(ExtendedModule)
            check_method_extension(ThisModule, ExtendedModule, exported)
        end
        return nothing
    end

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

    macro define_macro(macro_name::Symbol, pkg_sym=:StanfordAA228V)
        macro_name_str = string(macro_name)
        pkg_str = string(pkg_sym)
        quote
            macro $(esc(macro_name))(func_def)
                local name_str = $(macro_name_str)
                local pkg = $(pkg_str)

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

                check_call = Expr(:call, :check_method_extension, :(@__MODULE__), :(Symbol($pkg)))

                # Return both definitions
                return quote
                    $(esc(check_call))
                    $(esc(new_func_def))
                    $(esc(old_func_def))
                end
            end
        end
    end

    @define_macro small StanfordAA228V
    @define_macro medium StanfordAA228V
    @define_macro large StanfordAA228V
end
