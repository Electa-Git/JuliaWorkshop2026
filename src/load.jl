module Load

import ..Serialisation as SR

export DampedLoad, SinusoidalLoadProfile, ConstantLoadProfile

Base.@kwdef struct DampedLoad{P, T}
    profile::P
    B::T
    J::T
    function DampedLoad(profile::P, B::T, J::T) where {P, T}
        @assert B > 0 && J > 0
        new{P, T}(profile, B, J)
    end
end

Base.@kwdef struct SinusoidalLoadProfile{T}
    offset::T
    amplitude::T
end

Base.@kwdef struct ConstantLoadProfile{T}
    value::T
end

function torque(profile::SinusoidalLoadProfile{T}, t) where {T}
    profile.offset + profile.amplitude * sin(2 * T(pi) * t)
end
function torque(profile::ConstantLoadProfile{T}, t) where {T}
    profile.value
end
function derivative(load::DampedLoad, ω, T, t)
    (; dω = (-load.B - torque(load.profile, t) + T) / load.J)
end

function SR.deserialise(cfg, target::Type{<:DampedLoad}, context)
    profile = SR.deserialise(
        cfg[:profile], Dict(
            "sinusoidal" => SinusoidalLoadProfile,
            "constant" => ConstantLoadProfile,
        )[cfg[:profile][:type]], context
    )
    DampedLoad(profile, cfg[:B], cfg[:J])
end
function SR.deserialise(cfg, target::Type{<:ConstantLoadProfile}, context)
    ConstantLoadProfile(cfg[:value])
end
function SR.deserialise(cfg, target::Type{<:SinusoidalLoadProfile}, context)
    SinusoidalLoadProfile(cfg[:offset], cfg[:amplitude])
end

end # module Load
