module DCMotor
export Anchor,
    ExcitationWinding,
    Series,
    Parallel,
    Independent,
    DCMotorWithWinding,
    derivative,
    DCMotorData,
    torque

struct Anchor{T}
    R::T
    L::T
    k::T
    function Anchor(R::T, L::T, k::T) where {T}
        @assert R > 0 && L > 0 && k > 0
        new{T}(R, L, k)
    end
end
function Anchor(; R, L, n_nom, Pme, I_a_nom, I_b_nom)
    ω_nom = n_nom * 2 * pi / 60
    T_nom = Pme / ω_nom
    k = T_nom / I_a_nom / I_b_nom
    Anchor(R, L, k)
end

struct ExcitationWinding{T}
    R::T
    L::T
    function ExcitationWinding(R::T, L::T) where {T}
        @assert R > 0 && L > 0
        new{T}(R, L)
    end
end

abstract type AbstractDCMotorExcitation end

struct Series{T} <: AbstractDCMotorExcitation
    winding::ExcitationWinding{T}
end
struct Parallel{T} <: AbstractDCMotorExcitation
    winding::ExcitationWinding{T}
end
struct Independent{T} <: AbstractDCMotorExcitation
    winding::ExcitationWinding{T}
end
struct DCMotorWithWinding{E <: AbstractDCMotorExcitation, T}
    anchor::Anchor{T}
    excitation::E
end

emf(motor::DCMotorWithWinding, i_b, ω) = motor.anchor.k * i_b * ω
torque(motor::DCMotorWithWinding, i_a, i_b) = motor.anchor.k * i_a * i_b
torque(motor::DCMotorWithWinding{<:Series}, i_a, i_b) = motor.anchor.k * i_a^2
derivative(anchor::Anchor, u, i, e) = (u - e - i * anchor.R) / anchor.L
derivative(winding::ExcitationWinding, u, i) = (u - i * winding.R) / winding.L
function derivative(motor::DCMotorWithWinding{<:Series}, u_a, u_b, i_a, i_b, ω)
    e = emf(motor, i_a, ω)
    # U_a = La di/dt + Ra i + EMF + Rb i + Lb di/dt = 0
    R = motor.anchor.R + motor.excitation.winding.R
    L = motor.anchor.L + motor.excitation.winding.L
    di = (u_a - e - i_a * R) / L
    (; di_a = di, di_b = zero(i_b))
end
function derivative(motor::DCMotorWithWinding{<:Independent}, u_a, u_b, i_a, i_b, ω)
    e = emf(motor, i_b, ω)
    di_a = derivative(motor.anchor, u_a, i_a, e)
    di_b = derivative(motor.excitation.winding, u_b, i_b)
    (; di_a, di_b)
end
function derivative(motor::DCMotorWithWinding{<:Parallel}, u_a, u_b, i_a, i_b, ω)
    e = emf(motor, i_b, ω)
    di_a = derivative(motor.anchor, u_a, i_a, e)
    di_b = derivative(motor.excitation.winding, u_a, i_b)
    (; di_a, di_b)
end
end
