import UnicodePlots
import TimeToPublication

mypaper = TimeToPublication.Paper(60, 90)
days_to_publication = TimeToPublication.simulate(mypaper, 10_000)

display_result(result::Vector{Float64}) = UnicodePlots.histogram(result, nbins=60, vertical=true, border=:solid, xlabel="Days to publication", ylabel="Samples")
display_result(days_to_publication)
