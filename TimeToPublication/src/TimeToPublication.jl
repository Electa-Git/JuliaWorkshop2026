module TimeToPublication

import Distributions

export Paper, simulate

struct Paper
    writing_days::Distributions.Erlang{Int}
    review_days::Distributions.Exponential{Float64}
    Paper(writing_avg, review_avg) = new(Distributions.Erlang(writing_avg), Distributions.Exponential(review_avg))
end
sample(paper::Paper) = rand(paper.writing_days) + rand(paper.review_days)
simulate(paper::Paper, trials::Int) = [sample(paper) for _ in 1:trials]

end # module TimeToPublication
