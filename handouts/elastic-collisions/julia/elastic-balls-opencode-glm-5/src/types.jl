abstract type AbstractShape end
abstract type AbstractBoundary end

struct Vec2D{T<:Real}
    x::T
    y::T
end

Base.:+(a::Vec2D, b::Vec2D) = Vec2D(a.x + b.x, a.y + b.y)
Base.:-(a::Vec2D, b::Vec2D) = Vec2D(a.x - b.x, a.y - b.y)
Base.:*(a::Vec2D, s::Real) = Vec2D(a.x * s, a.y * s)
Base.:*(s::Real, a::Vec2D) = a * s
Base.:/(a::Vec2D, s::Real) = Vec2D(a.x / s, a.y / s)

dot(a::Vec2D, b::Vec2D) = a.x * b.x + a.y * b.y
norm(a::Vec2D) = sqrt(dot(a, a))
normalize(a::Vec2D) = a / norm(a)

struct Ball{T<:Real} <: AbstractShape
    position::Vec2D{T}
    velocity::Vec2D{T}
    radius::T
    mass::T
    color::Symbol
    id::Int
end

function Ball(pos::Tuple{T,T}, vel::Tuple{T,T}, radius::T, mass::T; 
              color::Symbol=:blue, id::Int=0) where {T<:Real}
    Ball(Vec2D(pos[1], pos[2]), Vec2D(vel[1], vel[2]), radius, mass, color, id)
end

struct RectBoundary{T<:Real} <: AbstractBoundary
    xmin::T
    xmax::T
    ymin::T
    ymax::T
end

RectBoundary(width::Real, height::Real) = RectBoundary(0.0, width, 0.0, height)

struct SimulationConfig{T<:Real}
    dt::T
    max_time::T
    boundary::RectBoundary{T}
    restitution::T
end

function SimulationConfig(; dt::Real=0.01, max_time::Real=10.0,
                          width::Real=10.0, height::Real=10.0,
                          restitution::Real=1.0)
    SimulationConfig(dt, max_time, RectBoundary(width, height), restitution)
end

struct SimulationState{T<:Real}
    time::T
    balls::Vector{Ball{T}}
end

mutable struct Simulation{T<:Real}
    config::SimulationConfig{T}
    balls::Vector{Ball{T}}
    time::T
    history::Vector{SimulationState{T}}
    record_history::Bool
end

function Simulation(balls::Vector{Ball{T}}, config::SimulationConfig{T};
                    record_history::Bool=false) where {T<:Real}
    Simulation(config, balls, zero(T), SimulationState{T}[], record_history)
end

function Simulation(balls::Vector{Ball{T}}; kwargs...) where {T<:Real}
    config = SimulationConfig(; kwargs...)
    Simulation(balls, config; record_history=get(kwargs, :record_history, false))
end
