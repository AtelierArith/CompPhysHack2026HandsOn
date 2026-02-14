using StaticArrays
using Colors
using LinearAlgebra

"""
    Vec2 = SVector{2, Float64}

Stack-allocated 2D vector type.
"""
const Vec2 = SVector{2, Float64}

"""
    Ball

Immutable struct representing a ball with position, velocity, mass, radius, and color.
"""
struct Ball
    pos::Vec2
    vel::Vec2
    mass::Float64
    radius::Float64
    color::RGB{Float64}

    function Ball(pos::Vec2, vel::Vec2, mass::Float64, radius::Float64, color::RGB{Float64})
        mass > 0 || throw(ArgumentError("mass must be positive, got $mass"))
        radius > 0 || throw(ArgumentError("radius must be positive, got $radius"))
        new(pos, vel, mass, radius, color)
    end
end

function Ball(; pos, vel=Vec2(0.0, 0.0), mass=1.0, radius=0.5, color=RGB(1.0, 0.0, 0.0))
    Ball(Vec2(pos...), Vec2(vel...), Float64(mass), Float64(radius), RGB{Float64}(color))
end

"""
    BoundaryBox

Rectangular simulation domain.
"""
struct BoundaryBox
    xmin::Float64
    xmax::Float64
    ymin::Float64
    ymax::Float64

    function BoundaryBox(xmin, xmax, ymin, ymax)
        xmin < xmax || throw(ArgumentError("xmin must be less than xmax"))
        ymin < ymax || throw(ArgumentError("ymin must be less than ymax"))
        new(Float64(xmin), Float64(xmax), Float64(ymin), Float64(ymax))
    end
end

function BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0)
    BoundaryBox(xmin, xmax, ymin, ymax)
end

"""
    SimulationState

Mutable state for the simulation, holding balls, boundary, time, and timestep.
"""
mutable struct SimulationState
    balls::Vector{Ball}
    boundary::BoundaryBox
    time::Float64
    dt::Float64

    function SimulationState(balls::Vector{Ball}, boundary::BoundaryBox, time::Float64, dt::Float64)
        dt > 0 || throw(ArgumentError("dt must be positive, got $dt"))
        new(balls, boundary, time, dt)
    end
end

function SimulationState(balls::Vector{Ball}; boundary=BoundaryBox(), dt=0.01)
    SimulationState(balls, boundary, 0.0, Float64(dt))
end
