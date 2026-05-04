julia --project run.jl --output /dev/null --plot-output plot_series.png system_series.yaml > /dev/null
julia --project run.jl --output /dev/null --plot-output plot_parallel.png system_parallel.yaml > /dev/null
julia --project run.jl --output /dev/null --plot-output plot_independent.png system.yaml > /dev/null
