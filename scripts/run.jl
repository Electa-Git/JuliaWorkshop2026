import CSV
import Dates
using BenchmarkTools

### * Config
output_file = "result.csv"

## ** Time
tstart = 0.0   # s
tend = 5.0     # s
tstep = 0.0001 # s

### * Constants
### ** Motor nominal characteristics
# these characteristics have been taken from
# Elektrische Energie en Aandrijvingen Exercise Session 3 Exercise 1
Pme = 18.9e3  # W
U_a = 470     # V
U_b = 170     # V
I_a_nom = 49  # A
I_b_nom = 4.9 # A
n_nom = 1285  # rpm
R_a = 1.46    # Ω

# these characteristics have been made up
L_b = 1.0e-1 # H
L_a = 1.0e-1 # H

### *** Calculate machine constant from nominal characteristics
ω_nom = n_nom * 2 * pi / 60   # rad/s
T_nom = Pme / ω_nom           # Nm
k = T_nom / I_a_nom / I_b_nom # Nm/A^2
R_b = U_b / I_b_nom           # Ω

### ** Load
J = 1.0                                         # kgm^2
B = 1.0                                         # kgm^2/s
T_u(t, T_nom) = T_nom * (0.5 + 0.25 * sin(2 * pi * t)) # Nm

### * Initialize

# start of timing for benchmarking purposes
function run_loop(; tstart, tend, tstep, U_a, U_b, B, J, L_a, L_b, R_a, R_b, k, T_nom)
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

@benchmark run_loop(; tstart, tend, tstep, U_a, U_b, B, J, L_a, L_b, R_a, R_b, k, T_nom)
(ω_vec, i_a_vec, i_b_vec) = run_loop(; tstart, tend, tstep, U_a, U_b, B, J, L_a, L_b, R_a, R_b, k, T_nom)

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
