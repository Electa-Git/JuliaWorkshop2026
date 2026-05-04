module PowerSource

import ..Serialisation as SR

export GenericPowerSource, ConstantVoltagePowerSource, SpeedControlPowerSource, AnchorVoltageDip, ExcitationVoltageDip

"""
    This type is only for dispatching, never instantiate it
"""
struct GenericPowerSource
    GenericPowerSource() = MethodError(GenericPowerSource, ())
end

Base.@kwdef struct ConstantVoltagePowerSource{T}
    U_a::T
    U_b::T
end

function voltages(source::ConstantVoltagePowerSource, state, inputs, time)
    (; U_a = source.U_a, U_b = source.U_b)
end

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

Base.@kwdef struct VoltageDip{T}
    U_pre::T
    U_during::T
    U_post::T
    t_start::T
    t_stop::T
    function VoltageDip(U_pre::T, U_during::T, U_post::T, t_start::T, t_stop::T) where {T}
        @assert t_start <= t_stop
        new{T}(U_pre, U_during, U_post, t_start, t_stop)
    end
end
VoltageDip(U_pre, U_during, t_start, t_stop) = VoltageDip(U_pre, U_during, U_pre, t_start, t_stop)

struct AnchorVoltageDip{T}
    dip::VoltageDip{T}
    U_b::T
end

struct ExcitationVoltageDip{T}
    U_a::T
    dip::VoltageDip{T}
end

function voltages(source::VoltageDip, state, inputs, time)
    time < source.t_start && return source.U_pre
    time < source.t_stop && return source.U_during
    source.U_post
end
function voltages(source::AnchorVoltageDip, state, inputs, time)
    (U_a = voltages(source.dip, state, inputs, time), U_b = source.U_b)
end
function voltages(source::ExcitationVoltageDip, state, inputs, time)
    (U_a = source.U_a, U_b = voltages(source.dip, state, inputs, time))
end

function SR.deserialise(cfg, ::Type{GenericPowerSource}, context)
    target = Dict(
        "constant" => ConstantVoltagePowerSource,
        "anchordip" => AnchorVoltageDip,
        "excitationdip" => AnchorVoltageDip,
        "speedcontrol" => SpeedControlPowerSource
    )[cfg[:type]]
    newcfg = deepcopy(cfg)
    pop!(newcfg, :type) # to remove this unnecessary kwarg
    SR.deserialise(
        newcfg,
        target,
        context
    )
end
function SR.deserialise(cfg, ::Type{<:ConstantVoltagePowerSource}, context)
    ConstantVoltagePowerSource(; cfg...)
end
function SR.deserialise(cfg, ::Type{<:SpeedControlPowerSource}, context)
    SpeedControlPowerSource(; cfg...)
end
function SR.deserialise(cfg, ::Type{<:VoltageDip}, context)
    U_pre = get(cfg, :U_pre, context[:U_pre])
    U_post = get(cfg, :U_post, U_pre)
    (; U_during, t_start, t_end) = (; cfg...)
    VoltageDip(U_pre, U_during, U_post, t_start, t_end)
end
function SR.deserialise(cfg, ::Type{<:ExcitationVoltageDip}, context)
    context[:U_pre] = get(cfg, :U_b, nothing)
    dip = SR.deserialise(cfg, VoltageDip, context)
    ExcitationVoltageDip(cfg[:U_a], dip)
end
function SR.deserialise(cfg, ::Type{<:AnchorVoltageDip}, context)
    context[:U_pre] = get(cfg, :U_a, nothing)
    dip = SR.deserialise(cfg, VoltageDip, context)
    AnchorVoltageDip(dip, cfg[:U_b])
end

end # module PowerSource
