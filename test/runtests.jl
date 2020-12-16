import DoctorDocstrings: list_no_docs
using Test
using TerminalMenus
using Printf
using TypedTables

    module testme
        struct Foo end

        f() = nothing

        """
        hello

        Examples
        =======

        ```jldoctest
        julia> 3+3
        6
        ```
        """
        g() = nothing

        h() = 1

        """
        yolo swag
        """
        i() = 0

        """

        j(type, str; base)

        parse is a number ....

        !!! note

            
        """
        j() = 0
        export f, g, h, i, j
    end

#@testset "DoctorDocstrings.jl" begin
    # Write your tests here.

    getdocs(f) = Docs.Text(Docs.doc(f))
    hasdocs(f) = !occursin(r"^No documentation found.", string(getdocs(f)))
    function hasexamples(f)
        s = string(getdocs(f))
        return occursin("Examples", s) && occursin("jldoctest", s) && occursin("julia>", s)
    end

    @test hasdocs(testme.g)
    @test hasexamples(testme.g)
    @test hasdocs(testme.i)
    @test !hasexamples(testme.i)

   # list = list_no_docs(testme)
   # @test length(list) == 24
   # @test list[2,3] == "-"
   # @test list[3,3] == "Yes"
   # @test all(list[4:7, 3] .== "-")

    ###################



getdocs(f) = Docs.Text(Docs.doc(f))
hasdocs(f) = !occursin(r"^No documentation found.", string(getdocs(f)))

function hasexamples(f)
    s = string(getdocs(f))
    return occursin("Examples", s) && occursin("jldoctest", s) && occursin("julia>", s)
end


function make_data(mod)
    col1 = [getfield(mod, i) for i in names(mod)]
    col2 = [hasdocs(j) for j in col1]
    col3 = [hasexamples(k) for k in col1]

    f1 = "%"
    f2 = @sprintf("%.2f", count(hasdocs(j) for j in col1)/length(col1)) 
    f3 = @sprintf("%.2f", count(hasexamples(k) for k in col1)/length(col3))
    footer = [f1 f2 f3]
    #println("Totals: $footer")

    data = vcat(hcat(col1, col2, col3), footer)
    return data
end

#function format_data(data, fun = false)
#    if !fun # Boo! :(
#        nope = '-'
#        yup = "Yes"
#    else    # Yay! :)
#        nope = '💩'
#        yup = '🎉'
#    end
#    f_data = copy(data) 
#    len = size(data)[2]
#    # God this is ugly
#    for i in len-1:len
#        f_data[i,2] = f_data[i, 2] ? yup : nope
#        f_data[i,3] = f_data[i, 3] ? yup : nope
#    end
#    f_data
#end

function list_no_docs(mod, fun = false, footer = true)
    data = make_data(mod)
#    f_data = format_data(data, fun)
    table = Table(Functions = data[:,1], Docs = data[:,2], Examples = data[:,3])
#    return f_data, table
return footer ? table[1:end-1, :] : table
end

# TODO Fix buggy shell and pkg starting lines
function history_parser(n = 50, maxlen = 1000)
    count = 0
    lines = reverse(readlines(REPL.find_hist_file()))
    len = length(lines)
    res = String[]
    i = 2
    while count < n && i < min(len, maxlen)
        temp = ""
        start = ""
        if endswith(lines[i], "julia")
            start = "julia> "
        elseif endswith(lines[i], "shell")
                start = ";"
        elseif endswith(lines[i], "pkg")
                start = "]"
        end
        # skip over the # time
        i += 2
        while !startswith(lines[i], "# mode: ") && i < min(len, maxlen)
            temp = lines[i][2:end] * '\n' * temp
            i += 1
        end
        push!(res, start * temp)
        count += 1
    end
    reverse!(res)
end

function pickandcopy(n=25, keeprepl = false)
    options = history_parser(n)
    menu = MultiSelectMenu(options, pagesize = n)
    choices = request("Pick your history to copy:", menu)
    picks = join([options[i] for i in choices], '\n')
    if length(choices) > 0
        println("Copied $(length(choices)) items to clipboard")
    else
        println("Boo :(")
    end
    picks
end

findfixables(table) = table.Functions[.!(table.Docs .| table.Examples)]

function buildpastestring(template_str, copypicks)
    template_str * """
    Examples
    ====
    ```jldoctest
    """ * copypicks * raw"```\"\"\""
end
#1. Get REPL history DONE
#2. find first fixable doc string
#2.5 Choose a template
#3. append Example header * REPL History to template, 
#3.5 put that into the clipboard
#4. open editor
function preparedocfixes(mod, template = picktemplate(docstr_templates), nhistory = 25)
    picks = pickandcopy(nhistory)
    table = list_no_docs(mod, false)
    fixables = findfixables(table)
    if isempty(fixables)
        return println("Yay! All your exports have docs and examples!")
    end
    pastestring = buildpastestring(template, picks)
    clipboard(pastestring)
end

function picktemplate(docstr_templates)
    menu = RadioMenu(["Basic", "BlueStyle", "Type", "Package quickstart"])
    choice = request("Choose your template", menu)
    if choice != -1
        nothing
    else
        println("Menu canceled")
    end
    docstr_templates[choice]
end


doc_example_template = """

    foo(T) -> S

This function calls `foo`.

"""
BlueStyle_func_template = """
    mysearch(array::MyArray{T}, val::T; verbose=true) where {T} -> Int

Searches the `array` for the `val`. For some reason we don't want to use Julia's
builtin search :)

# Arguments
- `array::MyArray{T}`: the array to search
- `val::T`: the value to search for
#
# Keywords
- `verbose::Bool=true`: print out progress details

# Returns
- `Int`: the index where `val` is located in the `array`

# Throws
- `NotFoundError`: I guess we could throw an error if `val` isn't found.

Examples
====
 """

type_template = """
     MyArray{T,N}

My super awesome array wrapper!

# Fields
- `data::AbstractArray{T,N}`: stores the array being wrapped
- `metadata::Dict`: stores metadata about the array
"""

quickstart_template = """

Welcome to MY_PACKAGE.jl!

This packages is useful for a) ... b) ... c) ...

Here's the top 5 workflows in this package

Examples
====
"""

docstr_templates = [doc_example_template, BlueStyle_func_template, type_template, quickstart_template]

function docstring_wizard(mod, quiet = true)
    if quiet
        println(banner)
    end
    t = list_no_docs(mod)

    todo_docs = t.Functions[findall(t.Docs)]
    todo_examples = t.Functions[findall(t.Examples)]
    todos = string.(Set([todo_docs, todo_examples]))
    docstr_templates = ["none", "example", "verbose"]
    menu = RadioMenu(docstr_templates)
    choice = request("Choose your template format", menu)

    todos_menu = RadioMenu(todos)
    choice = request("Choose a function to work on", todos_menu)

    if choice != -1
        println("")
    end
end

banner = raw"""
   ..____.......____................._........_...................._._.
   .|.._.\._.__|.._.\..___...___.___|.|_._.__(_)_.__...__._.___...(_).|
   .|.|.|.|.'__|.|.|.|/._.\./.__/.__|.__|.'__|.|.'_.\./._ ./.__|..|.|.|
   .|.|_|.|.|_.|.|_|.|.(_).|.(__\__.\.|_|.|..|.|.|.|.|.(_|.\__.\_.|.|.|
   .|____/|_(_)|____/.\___/.\___|___/\__|_|..|_|_|.|_|\__,.|___(_)/.|_|
   ...................................................|___/.....|__/...
   For the Julia community with <3
"""

#Maybe piracy?



#end
