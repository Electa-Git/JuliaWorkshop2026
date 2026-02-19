module MyModel

"""
Dynamic model of a DC motor with independent winding and armature
excitation voltages.

# Parameters
some more information...
"""
struct IndependentDCMotor{T}
    Pme::T
    U_b_nom::T
    I_a_nom::T
    I_b_nom::T
    n_nom::T
    R_a::T
    L_a::T
    L_b::T
    ω_nom::T
    T_nom::T
    k::T
    R_b::T
end

function IndependentDCMotor(;
        Pme,
        U_b_nom,
        I_a_nom,
        I_b_nom,
        n_nom,
        R_a,
        L_a,
        L_b,
    )

    ω_nom = n_nom * 2 * pi / 60
    T_nom = Pme / ω_nom
    k = T_nom / I_a_nom / I_b_nom
    R_b = U_b_nom / I_b_nom

    IndependentDCMotor(
        Pme,
        U_b_nom,
        I_a_nom,
        I_b_nom,
        n_nom,
        R_a,
        L_a,
        L_b,
        ω_nom,
        T_nom,
        k,
        R_b,
    )
end

function di(motor::IndependentDCMotor, state, inputs, time)
    (; i_a, i_b, ω) = state
    (; U_a, U_b) = inputs
    e = motor.k * i_b * ω
    di_a = (U_a - e - motor.R_a * i_a) / motor.L_a
    di_b = (U_b - motor.R_b * i_b) / motor.L_b
    (; di_a, di_b)
end

function torque(motor::IndependentDCMotor, state, inputs, time)
    (; i_a, i_b) = state
    motor.k * i_a * i_b
end

"""
Model of the studied sinusoidal load: ``offset + amplitude * sin(2 * pi * T)``

# Parameters
...
"""
Base.@kwdef struct SinusoidalLoadProfile{T}
    offset::T
    amplitude::T
end

function torque(load::SinusoidalLoadProfile{T}, state, inputs, time) where {T}
    -(load.offset + load.amplitude * sin(2 * T(pi) * time))
end

"""
Add some damper to another load profile

# Parameters
...
"""
Base.@kwdef struct DampedLoad{I, T}
    inner::I
    B::T
    J::T
end

DampedLoad(d::Dict{Symbol}) = DampedLoad(d[:B], d[:J], d[:inner_type], d[:inner_kwargs])
function DampedLoad(B, J, inner_type, inner_kwargs)
    if lowercase(inner_type) == "sinusoidalloadprofile"
        inner_type = SinusoidalLoadProfile
    else
        throw("Unknown profile type")
    end
    inner = inner_type(; inner_kwargs...)
    DampedLoad(inner, B, J)
end

function dω(load::DampedLoad, state, inputs, time)
    ω = state[:ω]
    T_inner = torque(load.inner, state, inputs, time)
    T_load = T_inner - load.B * ω
    T_motor = inputs[:T_motor]
    (T_motor + T_load) / load.J
end

"""
Power source model with constant voltage
"""
Base.@kwdef struct ConstantVoltagePowerSource{T}
    U_a::T
    U_b::T
end

function voltages(source::ConstantVoltagePowerSource, state, inputs, time)
    (; U_a = source.U_a, U_b = source.U_b)
end

"""
Add a proportional controller to regulate the angular velocity of the motor
"""
Base.@kwdef struct SpeedControlPowerSource{T}
    ω_ref::T
    K_p::T
    U_a_bias::T
    U_b::T
end

function voltages(source::SpeedControlPowerSource, state, inputs, time)
    Δω = source.ω_ref - state[:ω]
    U_a = source.U_a_bias + source.K_p * Δω
    (; U_a, U_b = source.U_b)
end

"""
read either a SpeedControlPowerSource or a voltage power source from the config file
"""
function read_power_source(data)
    if haskey(data, :ω_ref)
        SpeedControlPowerSource(; data...)
    else
        ConstantVoltagePowerSource(; data...)
    end
end

"""
Build a function to simulate from the high-level component structs
"""
function build_simulate_function(motor, load, powersource)
    function f(state, inputs, time)
        (; U_a, U_b) = voltages(powersource, state, inputs, time)
        T_motor = torque(motor, state, (; U_a, U_b), time)
        delω = dω(load, state, (; T_motor), time)
        deli = di(motor, state, (; U_a, U_b), time)
        return (; dω = delω, deli...)
    end
end

function build_simulate_function(motor, load)
    function f(state, inputs, time)
        # expect parameters to be provided by the simulation
        (; U_a, U_b) = inputs
        T_motor = torque(motor, state, (; U_a, U_b), time)
        delω = dω(load, state, (; T_motor), time)
        deli = di(motor, state, (; U_a, U_b), time)
        return (; dω = delω, deli...)
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
