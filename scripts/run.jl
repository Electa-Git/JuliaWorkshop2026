import CSV
import Dates
using BenchmarkTools
import YAML
import ArgParse
import Revise
Revise.includet("../src/dcmotor.jl")
using .DCMotor

### * Parse arguments
function parse_cmd()
    s = ArgParse.ArgParseSettings()
    ArgParse.@add_arg_table s begin
        "--benchmark", "-b"
        action = :store_true
        "--output", "-o"
        help = "output file"
        arg_type = String
        default = "result.csv"
        "system"
        help = "system config file"
        required = true
    end
    if isinteractive()
        Dict("output" => "result.csv", "system" => "system_parallel.yaml", "benchmark" => true)
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

### *** Calculate machine constant from nominal characteristics
let d = data[:motor]
    (; U_b, n_nom, Pme, I_a_nom, I_b_nom) = (; d...)
    ω_nom = n_nom * 2 * pi / 60   # rad/s
    T_nom = Pme / ω_nom           # Nm
    R_b = U_b / I_b_nom           # Ω
    d[:T_nom] = T_nom
    anchor = Anchor(; R = d[:R_a], L = d[:L_a], I_a_nom, I_b_nom, Pme, n_nom)
    winding = ExcitationWinding(R_b, d[:L_b])
    setupkey = get(d, :setup, "independent")
    excitation = if setupkey == "independent"
        Independent(winding)
    elseif setupkey == "parallel"
        Parallel(winding)
    elseif setupkey == "series"
        Series(winding)
    else
        throw(KeyError(setupkey))
    end
    d[:motor] = DCMotorWithWinding(anchor, excitation)
end

### ** Load
T_u(t, T_nom) = T_nom * (0.5 + 0.25 * sin(2 * pi * t)) # Nm

### * Initialize

# start of timing for benchmarking purposes
function run_loop(; tstart, tend, tstep, motor, T_nom, B, J, U_a, U_b, kwargs...)
    trange = range(start = tstart, stop = tend, step = tstep)

    ω_vec = zeros(length(trange))
    i_a_vec = zeros(length(trange))
    i_b_vec = zeros(length(trange))

    ### * Simulate

    for (idx, t) in enumerate(trange[begin:(end - 1)])
        ω = ω_vec[idx]
        i_a = i_a_vec[idx]
        i_b = i_b_vec[idx]

        Tm = torque(motor, i_a, i_b)
        dω = (-B * ω - T_u(t, T_nom) + Tm) / J
        di_a, di_b = derivative(motor, U_a, U_b, i_a, i_b, ω)

        # Forward Euler x(t+dt) = x(t) + dt * dx/dt (t)
        ω_new = ω + dω * tstep
        i_a_new = i_a + di_a * tstep
        i_b_new = i_b + di_b * tstep

        ω_vec[idx + 1] = ω_new
        i_a_vec[idx + 1] = i_a_new
        i_b_vec[idx + 1] = i_b_new
    end
    return (ω_vec, i_a_vec, i_b_vec)
end
flat_data = reduce(merge, values(data))

if args["benchmark"]
    println("pass data as keyword arguments")
    display(@benchmark run_loop(; flat_data...))
end

(ω_vec, i_a_vec, i_b_vec) = run_loop(; flat_data...)

### * Save result
time = range(tstart, step = tstep, length = length(ω_vec)) # avoid off-by-one errors
d = Dict("omega" => ω_vec, "i_a" => i_a_vec, "i_b" => i_b_vec, "time" => time)

println("Writing results")
CSV.write(output_file, d)

println("Plotting results")
using CairoMakie

fig = Figure();
ax = Axis(fig[1, 1], xlabel = "Time [s]")
lines!(ax, time, ω_vec, label = "ω [rad/s]")
lines!(ax, time, i_a_vec, label = "i_a [A]")
lines!(ax, time, i_b_vec, label = "i_b [A]")
axislegend(ax, position = :rt)
save("plot.png", fig)

println("Done")
