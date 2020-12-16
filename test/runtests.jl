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

    data = vcat(hcat(col1, col2, col3), footer)
    return data
end

function list_no_docs(mod, fun = false)
    if !fun # Boo! :(
        nope = '-'
        yup = "Yes"
    else    # Yay! :)
        nope = '💩'
        yup = '🎉'
    end
    data = make_data(mod)

    table = Table(Functions = data[:,1], Docs = data[:,2], Examples = data[:,3])
    return table
end



#end
