import CSV
import Dates
using BenchmarkTools
import YAML
import ArgParse
import MyModel

### * Parse arguments
function parse_cmd()
    s = ArgParse.ArgParseSettings()
    ArgParse.@add_arg_table s begin
        "--output", "-o"
        help = "output file"
        arg_type = String
        default = "result.csv"
        "system"
        help = "system config file"
        required = true
    end
    if isinteractive()
        Dict("output" => "result.csv", "system" => "system.yaml")
    else
        ArgParse.parse_args(s)
    end
end

### * Config
args = parse_cmd()
output_file = args["output"]
config_file = args["system"]
data = try
    YAML.load_file(config_file, dicttype = Dict{Symbol, Float64})
catch err
    # cannot parse everything as a Dict{Symbol, Float64}
    # this is the case since we use nested dictionaries
    YAML.load_file(config_file, dicttype = Dict{Symbol, Any})
end

## ** Time
(; tstart, tend, tstep) = (; data[:time]...)

### * Instantiate model and simulate it
motor = MyModel.IndependentDCMotor(; data[:motor]...)
load = MyModel.DampedLoad(data[:load])
powersource = MyModel.read_power_source(data[:powersource])

f = MyModel.build_simulate_function(motor, load, powersource)

display(@benchmark MyModel.simulate(f, tstart, tend, tstep))

(ω_vec, i_a_vec, i_b_vec) = MyModel.simulate(f, tstart, tend, tstep)

### * Save result
time = range(tstart, step = tstep, length = length(ω_vec)) # avoid off-by-one errors
d = Dict("omega" => ω_vec, "i_a" => i_a_vec, "i_b" => i_b_vec, "time" => time)

println("Writing results")
CSV.write(output_file, d)

println("Plotting results")
using CairoMakie

fig = Figure();
ax = Axis(fig[1, 1], xlabel = "Time [s]", yticks = 0:50:250)
lines!(ax, time, ω_vec, label = "ω [rad/s]")
lines!(ax, time, i_a_vec, label = "i_a [A]")
lines!(ax, time, i_b_vec, label = "i_b [A]")
axislegend(ax, position = :rt)
save("plot.png", fig)

println("Done")
