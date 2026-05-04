import Distributions
import UnicodePlots

struct Paper
    writing_days::Distributions.Erlang{Int}
    review_days::Distributions.Exponential{Float64}
    Paper(writing_avg, review_avg) = new(Distributions.Erlang(writing_avg), Distributions.Exponential(review_avg))
end
sample(paper::Paper) = rand(paper.writing_days) + rand(paper.review_days)
simulate(paper::Paper, trials::Int) = [sample(paper) for _ in 1:trials]

mypaper = Paper(60, 90)
days_to_publication = simulate(mypaper, 10_000)

display_result(result::Vector{Float64}) = UnicodePlots.histogram(result, nbins=60, vertical=true, border=:solid, xlabel="Days to publication", ylabel="Samples")
display_result(days_to_publication)
