module MyModel

include("serialisation.jl")
include("dcmotor.jl")
include("load.jl")
include("powersource.jl")

"""
Build a function to simulate from the high-level component structs
"""
function build_simulate_function(motor, load, powersource)
    function f(state, inputs, time)
        (; ω, i_a, i_b) = state
        (; U_a, U_b) = PowerSource.voltages(powersource, state, inputs, time)
        T_motor = DCMotor.torque(motor, i_a, i_b)
        dω = Load.derivative(load, state, T_motor, time)
        di = DCMotor.derivative(motor, U_a, U_b, i_a, i_b, ω)
        return (; dω..., di...)
    end
end

"""
Simulate a model with the provided parameters
"""
function simulate(f, tstart, tend, tstep, parameters = NamedTuple())
    trange = range(start = tstart, stop = tend, step = tstep)
    ω_vec = zeros(length(trange))
    i_a_vec = zeros(length(trange))
    i_b_vec = zeros(length(trange))
    for (idx, t) in enumerate(trange[begin:(end - 1)])
        ω = ω_vec[idx]
        i_a = i_a_vec[idx]
        i_b = i_b_vec[idx]

        (; dω, di_a, di_b) = f((; ω, i_a, i_b), parameters, t)

        ω_vec[idx + 1] = ω + dω * tstep
        i_a_vec[idx + 1] = i_a + di_a * tstep
        i_b_vec[idx + 1] = i_b + di_b * tstep
    end
    return (ω_vec, i_a_vec, i_b_vec)
end

end # module MyModel
