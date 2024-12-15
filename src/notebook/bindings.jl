struct DarkModeIndicator
    default::Bool
end

DarkModeIndicator(; default::Bool=false) = DarkModeIndicator(default)

function Base.show(io::IO, ::MIME"text/html", link::DarkModeIndicator)
    print(io, """
        <span>
        <script>
            const span = currentScript.parentElement
            span.value = window.matchMedia('(prefers-color-scheme: dark)').matches
        </script>
        </span>
    """)
end

Base.get(checkbox::DarkModeIndicator) = checkbox.default
Bonds.initial_value(b::DarkModeIndicator) = b.default
Bonds.possible_values(::DarkModeIndicator) = [false, true]
Bonds.validate_value(::DarkModeIndicator, val) = val isa Bool


struct OpenDirectory
    default::Bool
    text
end

OpenDirectory(text="Link"; default::Bool=false) = OpenDirectory(default, text)

function Base.show(io::IO, ::MIME"text/html", link::OpenDirectory)
    print(io, """
        <span>
        <code><a href='#;'>$(link.text)</a></code>
        <script>
            // Select elements relative to `currentScript`
            const span = currentScript.parentElement
            const link = span.querySelector("a")

            link.addEventListener("click", (e) => {
                span.value = true
                span.dispatchEvent(new CustomEvent("input"))
                span.value = false
                span.dispatchEvent(new CustomEvent("input"))
                e.preventDefault()
            })

            // Set the initial value
            span.value = false
        </script>
        </span>""")
end

Base.get(checkbox::OpenDirectory) = checkbox.default
Bonds.initial_value(b::OpenDirectory) = b.default
Bonds.possible_values(::OpenDirectory) = [false, true]
Bonds.validate_value(::OpenDirectory, val) = val isa Bool


struct LargeCheckBox
    default::Bool
    text
end

LargeCheckBox(; default::Bool=false, text="") = LargeCheckBox(default, text)

function Base.show(io::IO, ::MIME"text/html", button::LargeCheckBox)
    print(io, """<input class="checkbox-input" type="checkbox"$(button.default ? " checked" : "")> <label class="checkbox-label">$(button.text)</label>""")
end

Base.get(checkbox::LargeCheckBox) = checkbox.default
Bonds.initial_value(b::LargeCheckBox) = b.default
Bonds.possible_values(::LargeCheckBox) = [false, true]
Bonds.validate_value(::LargeCheckBox, val) = val isa Bool
