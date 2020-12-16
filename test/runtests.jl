using DoctorDocstrings
using TerminalUserInterfaces
using Test
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

@testset "DoctorDocstrings.jl" begin
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

    list = list_no_docs(testme)
    @test length(list) == 24
    @test list[2,3] == "-"
    @test list[3,3] == "Yes"
    @test all(list[4:7, 3] .== "-")

end
