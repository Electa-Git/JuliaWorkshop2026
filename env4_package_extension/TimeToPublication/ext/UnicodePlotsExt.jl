module UnicodePlotsExt

import TimeToPublication, UnicodePlots

TimeToPublication.display_result(result::Vector{Float64}) = UnicodePlots.histogram(result, nbins=60, vertical=true, border=:solid, xlabel="Days to publication", ylabel="Samples")

end # module UnicodePlotsExt
