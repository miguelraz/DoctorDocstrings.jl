module DoctorDocstrings
using TerminalMenus
using PrettyTables
using Printf
#using REPL

getdocs(f) = Docs.Text(Docs.doc(f))
hasdocs(f) = !occursin(r"^No documentation found.", string(getdocs(f)))

function hasexamples(f)
    s = string(getdocs(f))
    return occursin("Examples", s) && occursin("jldoctest", s) && occursin("julia>", s)
end

const conf = set_pt_conf(tf = tf_markdown, alignment = :c)

function list_no_docs(mod, fun = false)
    if !fun # Boo ! :(
        nope = '-'
        yup = "Yes"
    else
        nope = '💩'
        yup = '🎉'
    end
    header = ["Functions" "Docs" "Examples"]

    col1 = [getfield(mod, i) for i in names(mod)]
    col2 = [hasdocs(j) ? yup : nope for j in col1]
    col3 = [hasexamples(k) ? yup : nope for k in col1]

    f1 = "Total %"
    f2 = @sprintf("%.3f", count(hasdocs(j) for j in col1)/length(col1)) 
    f3 = @sprintf("%.3f", count(hasexamples(k) for k in col1)/length(col3))
    footer = [f1 f2 f3]

    data = string.(vcat(hcat(col1, col2, col3), footer))

    table = pretty_table(conf, data, header)

    return table
end


export list_no_docs

end




