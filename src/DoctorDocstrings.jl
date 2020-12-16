module DoctorDocstrings

getdocs(f) = Docs.Text(Docs.doc(f))
hasdocs(f) = !occursin(r"^No documentation found.", string(getdocs(f)))
function hasexamples(f)
    s = string(getdocs(f))
    return occursin("Examples", s) && occursin("jldoctest", s) && occursin("julia>", s)
end

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
    footer = [ "Total %" count(hasdocs(j) for j in col1)/length(col1) count(hasexamples(k) for k in col1)/length(col3)]
    return string.(vcat(header,hcat(col1, col2, col3), footer))
end


export list_no_docs

end




