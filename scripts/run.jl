import CSV
import Dates
using BenchmarkTools
import YAML

### * Config
output_file = "result.csv"
config_file = "system.yaml"
data = YAML.load_file(config_file)

## ** Time

### *** Calculate machine constant from nominal characteristics
let d = data["motor"]
    n_nom, Pme, I_a_nom, I_b_nom = d["n_nom"], d["Pme"], d["I_a_nom"], d["I_b_nom"]
    ω_nom = n_nom * 2 * pi / 60   # rad/s
    T_nom = Pme / ω_nom           # Nm
    k = T_nom / I_a_nom / I_b_nom # Nm/A^2
    R_b = U_b / I_b_nom           # Ω
    d["ω_nom"] = ω_nom
    d["T_nom"] = T_nom
    d["k"] = k
    d["R_b"] = R_b
end

### ** Load
T_u(t, T_nom) = T_nom * (0.5 + 0.25 * sin(2 * pi * t)) # Nm

### * Initialize

# start of timing for benchmarking purposes
function run_loop(; tstart, tend, tstep, U_a, U_b, B, J, L_a, L_b, R_a, R_b, k, T_nom, kwargs...)
    trange = range(start = tstart, stop = tend, step = tstep)

    ω_vec = zeros(length(trange))
    i_a_vec = zeros(length(trange))
    i_b_vec = zeros(length(trange))

    ### * Simulate

    for (idx, t) in enumerate(trange[begin:(end - 1)])
        ω = ω_vec[idx]
        i_a = i_a_vec[idx]
        i_b = i_b_vec[idx]
        e = k * i_b * ω
        Tm = k * i_a * i_b

        dω = (-B * ω - T_u(t, T_nom) + Tm) / J
        di_a = (U_a - e - R_a * i_a) / L_a
        di_b = (U_b - R_b * i_b) / L_b

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

flat_data = merge((Dict(Symbol(vk) => Float64(vv) for (vk, vv) in v) for v in values(data))...)

@benchmark run_loop(; flat_data...)
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
