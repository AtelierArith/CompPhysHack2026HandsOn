using StaticArrays
using Colors
using LinearAlgebra

"""Stack-allocated 2D vector."""
const Vec2 = SVector{2, Float64}

"""
    Ball

Immutable ball with position, velocity, mass, radius, and color.
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

"""Keyword constructor with sensible defaults."""
function Ball(; pos, vel=Vec2(0.0, 0.0), mass=1.0, radius=0.5,
               color=RGB{Float64}(0.2, 0.6, 1.0))
    Ball(Vec2(Float64.(pos)...), Vec2(Float64.(vel)...),
         Float64(mass), Float64(radius), RGB{Float64}(color))
end

"""
    BoundaryBox

Rectangular simulation domain defined by axis-aligned extents.
"""
struct BoundaryBox
    xmin::Float64
    xmax::Float64
    ymin::Float64
    ymax::Float64

    function BoundaryBox(xmin, xmax, ymin, ymax)
        xmin < xmax || throw(ArgumentError("xmin must be < xmax, got ($xmin, $xmax)"))
        ymin < ymax || throw(ArgumentError("ymin must be < ymax, got ($ymin, $ymax)"))
        new(Float64(xmin), Float64(xmax), Float64(ymin), Float64(ymax))
    end
end

BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0) =
    BoundaryBox(xmin, xmax, ymin, ymax)

"""
    SimulationState

Mutable container for the current simulation state.
"""
mutable struct SimulationState
    balls::Vector{Ball}
    boundary::BoundaryBox
    time::Float64
    dt::Float64

    function SimulationState(balls, boundary, time, dt)
        dt > 0 || throw(ArgumentError("dt must be positive, got $dt"))
        new(collect(Ball, balls), boundary, Float64(time), Float64(dt))
    end
end

SimulationState(balls::Vector{Ball}; boundary=BoundaryBox(), dt=0.01) =
    SimulationState(balls, boundary, 0.0, dt)
