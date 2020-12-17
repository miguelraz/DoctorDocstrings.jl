<!-- =============================
     DoctorDocstrings.jl
    ============================== -->

\begin{section}{title="About this Package", name="About"}

\lead{DoctorDocstrings.jl helps you list the exports in your package that don't have docstrings/examples, set a docstring template and copy your REPL history directly into the docstring.}

With it you can:

* `listdocs(OhMyREPL)` to get a `TypedTable` of the exports and if they have docs/examples.
* `diagnosedocs(LightGraphs)` to get a `TypedTable` of exports that need fixing.
* `pickandcopy(n)` to choose up to the last `n` items in your REPL and paste them into your clipboard
* `fixdocs()` to select from your REPL history and step into the last selection.

\end{section}


<!-- ==============================
     GETTING STARTED
     ============================== -->
\begin{section}{title="Getting started"}


In order to get started, just add the package (with **Julia ≥ 1.3**) and

```julia
julia> using DoctorDocstrings
julia> listdocs(DifferentialEquations)
julia> # Play in the REPL for a few commands
julia> fixdocs() 
```

\\



It's usually cumbersome to have to copy-paste your REPL history when you are exploring what works. Now, you can inject it into a docstring template. Just figure out which docstrings you are missing with `nodocs(Plots)`, type your setup into the REPL, select the appropriate history with `fixdocs()` and paste the docstring into your favorite editor.

\alert{This software is VERY much alpha, but it should work for simple module structures. `Base` in particular is tricky to handle. Many things are hardcoded and not too extensible. Please, if you find it borking out, send an issue/PR.}

\end{section}

<!-- ==============================
     Workflow 
     ============================== -->
\begin{section}{title="Workflow"}


Here's the result from running `diagnosedocs(OrdinaryDiffEq)`:

```julia-repl
julia> listdocs(OrdinaryDiffEq)
Table with 3 columns and 396 rows:
      Functions                  Docs   Examples
    ┌───────────────────────────────────────────
 1  │ AB3                        true   false
 2  │ AB4                        true   false
 3  │ AB5                        true   false
 4  │ ABDF2                      true   false
 5  │ ABM32                      true   false
 6  │ ABM43                      true   false
 7  │ ABM54                      true   false
 8  │ AN5                        false  false
 9  │ AbstractAnalyticalProblem  true   false
 10 │ AffineDiffEqOperator       true   false
...
```

If you want to get a list only of the offending exports, it would look like this:
```julia-repl
julia> diagnosedocs(LightGraphs)
[ Info: You should now write a few examples of a docstring for your functions in the REPL
[ Info: You will be able to copy/paste them by calling 'fixdocs()'
Table with 1 column and 65 rows:
      NeedFixes
    ┌────────────────────────────
 1  │ BarbellGraph
 2  │ BinaryTree
 3  │ BullGraph
 4  │ ChvatalGraph
 5  │ Circularladder_graph
 6  │ CliqueGraph
 7  │ CompleteBipartiteGraph
 8  │ CompleteDiGraph
 9  │ CompleteGraph
 10 │ CompleteMultipartiteGraph
```

(The `Info` prompt can be turned off with `diagnosedocs(LightGraphs, false)`.)

OK, let's say you decide to add some docstrings to the `CliqueGraph` function. Like any self-respecting Julian, we start to play around in the REPL.
```julia-repl
julia> g = CliqueGraph(3,3)
{9, 12} undirected simple Int64 graph

julia> nedges(g)
ERROR: UndefVarError: nedges not defined
Stacktrace:
 [1] top-level scope
   @ REPL[34]:1

julia> g[1,2]
ERROR: MethodError: no method matching getindex(::SimpleGraph{Int64}, ::Int64, ::Int64)
Closest candidates are:
  getindex(::AbstractGraph, ::Any) at /home/mrg/.julia/packages/LightGraphs/QpMj2/src/operators.jl:689
Stacktrace:
 [1] top-level scope
   @ REPL[35]:1
fadjlist ne
julia> g.ne
12

julia> g.fadjlist
9-element Vector{Vector{Int64}}:
 [2, 3, 4, 7]
 [1, 3]
 [1, 2]
 [1, 5, 6, 7]
 [4, 6]
 [4, 5]
 [1, 4, 8, 9]
 [7, 9]
 [7, 8]
julia> CliqueGraph(1,1);
```

Nice! After some mucking about, I figured out how to construct the examples to go into the docstring. But ughhhh, I made a few typos along the way. **No sweat!**, with `fixdocs()`, I can choose which previous inputs I want copied into my clipboard.

```julia-repl
Pick your history to copy:
[press: d=done, a=all, n=none]
   [X] julia> g = CliqueGraph(3,3)\n
   [ ] julia> nedges(g)\n
   [ ] julia> g[1,2]\n
 > [X] julia> g.ne\n
   [X] julia> g.fadjlist\n
   [ ] julia> pickandcopy(10)\n
   [ ] julia> newpage()\n
   [ ] ;serve()\n
   [ ] ;vim page/Project.toml\n
   [ ] ;cd page\n
```

This is the job of `pickandcopy`, which is **super useful** if you are preparing for a live demo and want to only copy your inputs that worked. Notice that I didn't select my flubs, and they don't get added to my clipboard.

Lastly, you will be prompted if you want to `@edit` your last selection. In the example above, I would jump straight in to edit the docstring for `CliqueGraph` with a chosen template.

The template will be chosen through a terminal menu, but you can define your own string and pass it to `fixdocs(template)` and it should `Just Work`TM.

The templates for the time being are `Basic, BlueStyle, Type, and Package quickstart/tldr`.

As always, PRs welcome.

\end{section}
