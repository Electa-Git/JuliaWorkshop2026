using CairoMakie
import CSV
import Tables

function makeplot(data)
    fig = Figure(size = (1600, 900))
    ax = Axis(fig[1, 1], xlabel = "Time[s]")
    lines!(ax, data.time, data.omega, label = "ω [rad/s]")
    lines!(ax, data.time, data.i_a, label = "i_a [A]")
    lines!(ax, data.time, data.i_b, label = "i_b [A]")
    axislegend(ax)
    fig
end

function main(args)
    for arg in args
        data = CSV.read(arg, Tables.columntable)
        fig = makeplot(data)
        save(replace(arg, ".csv" => ".png", "result" => "plot"), fig)
    end
end

abspath(PROGRAM_FILE) == @__FILE__() && main(ARGS)
