using DoctorDocstrings
using Test
using TerminalMenus
using Printf
using TypedTables
using REPL

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

    @test hasdocs(testme.g)
    @test hasexamples(testme.g)
    @test hasdocs(testme.i)
    @test !hasexamples(testme.i)

   # list = listdocs(testme)
   # @test length(list) == 24
   # @test list[2,3] == "-"
   # @test list[3,3] == "Yes"
   # @test all(list[4:7, 3] .== "-")

@test length(listdocs(testme)) == 7
@test length(diagnosedocs(testme)) == 3



end
