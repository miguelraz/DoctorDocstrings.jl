module DoctorDocstrings

using TerminalMenus
using Printf
using TypedTables
using REPL
import InteractiveUtils: clipboard, @edit

export list_no_docs, diagnosedocs, fixdocs, pickandcopy

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

    f1 = "Total %"
    f2 = @sprintf("%.2f", count(hasdocs(j) for j in col1)/length(col1)) 
    f3 = @sprintf("%.2f", count(hasexamples(k) for k in col1)/length(col3))
    footer = [f1 f2 f3]

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

function list_no_docs(mod, footer = true, fun = false)
    data = make_data(mod)
#    f_data = format_data(data, fun)
    table = Table(Functions = data[:,1], Docs = data[:,2], Examples = data[:,3])
#    return f_data, table
    return footer ? table : table[1:end-1, :]
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
    choiceset = request("Pick your history to copy:", menu)
    picks = [options[i] for i in sort(collect(choiceset))]
    latest_entry = picks[end]
    res = join(picks, '\n')
    if length(choiceset) > 0
        @info "Copied $(length(choiceset)) items to clipboard"
    else
        @info "Something got borked. Try again."
    end
    # TODO Fix this horrible hack to not get the "julia> "
    # latest_entry is a string, so this should "work"
    res, latest_entry[7:end]
end

findfixables(table) = table.Functions[.!(table.Docs .| table.Examples)]

function buildpastestring(template_str, copypicks)
    template_str * """
Examples
====
```jldoctest
""" * '\n' * copypicks * "\n```\n\"\"\""
end

#1. Get REPL history DONE
#2. find first fixable doc string
#2.5 Choose a template
#3. append Example header * REPL History to template, 
#3.5 put that into the clipboard
#4. open editor
function latesteditprompt(latest_entry)
    @info "Templated docstrings with example has been pasted into your system clipboard"
    @info "Would you like to @edit $(latest_entry[1:end-1]) ? Y/N"
    if any(occursin.(["yes", "Y", "YES", "y", "Yes"], readline()))
        expr = Meta.parse(latest_entry)
        @eval @edit $(expr)
    else
        @info "Didn't get a Yes/YES/y/Y/Yes answer. Appointment canceled."
    end
end

function instructprompt(doctarget = "your functions")
    @info "You should now write a few examples of a docstring for $doctarget in the REPL"
    @info "You will be able to copy/paste them by calling 'fixdocs()'"
end

function diagnosedocs(mod, verbose = false)
    table = list_no_docs(mod, false, false)
    fixables = findfixables(table)
    if isempty(fixables)
        return println("Yay! All your exports have docs and examples!")
    end
    instructprompt()
    return Table(NeedFixes = fixables)
end


function fixdocs(template = picktemplate(docstr_templates), nhistory = 25)
    picks, latest_entry = pickandcopy(nhistory)
    pastestring = buildpastestring(template, picks)
    clipboard(pastestring)
    latesteditprompt(latest_entry)
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
\"\"\"
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
""";

end

