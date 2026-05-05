module TimeToPublication

import Distributions

export Paper, simulate, display_result

struct Paper
    writing_days::Distributions.Erlang{Int}
    review_days::Distributions.Exponential{Float64}
    Paper(writing_avg, review_avg) = new(Distributions.Erlang(writing_avg), Distributions.Exponential(review_avg))
end
sample(paper::Paper) = rand(paper.writing_days) + rand(paper.review_days)
simulate(paper::Paper, trials::Int) = [sample(paper) for _ in 1:trials]
display_result(result::Vector{Float64}) = println("Expected time to publication: $(sum(result)/length(result)) days")

end # module TimeToPublication
