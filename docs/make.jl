using Documenter
using DoctorDocstrings

makedocs(
    sitename = "DoctorDocstrings",
    format = Documenter.HTML(),
    modules = [DoctorDocstrings]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#