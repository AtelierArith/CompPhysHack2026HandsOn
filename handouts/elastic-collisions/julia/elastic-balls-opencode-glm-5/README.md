# ElasticBalls.jl

A Julia package for simulating and visualizing elastic collisions of multiple balls in 2D space.

## Features

- **Type-safe ball types**: Parameterized types for numerical precision
- **Elastic collision physics**: Momentum and energy conserving collisions
- **Boundary collisions**: Balls bounce off rectangular boundaries
- **Real-time animation**: Interactive visualization with Plots.jl
- **Data export**: Save simulations to JSON and CSV formats

## Installation

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## Quick Start

```julia
using ElasticBalls

# Create random balls
balls = create_random_balls(10; width=10.0, height=10.0)

# Configure simulation
config = SimulationConfig(dt=0.01, max_time=5.0, width=10.0, height=10.0)

# Run simulation
sim = simulate(balls, config; record_history=true)

# Visualize final state
plt = visualize(sim)
savefig(plt, "simulation.png")

# Create animation
anim = animate_simulation(sim; fps=60)
gif(anim, "simulation.gif"; fps=60)

# Export data
export_trajectory_csv(sim, "trajectory.csv")
save_simulation(sim, "simulation.json")
```

## API

### Types

- `Ball{T}`: Represents a ball with position, velocity, radius, mass, and color
- `Simulation{T}`: Contains simulation configuration and state
- `SimulationConfig{T}`: Configuration parameters (dt, max_time, boundary, restitution)

### Functions

- `create_random_balls(n; kwargs...)`: Generate n random non-overlapping balls
- `simulate(balls, config; record_history=true)`: Run full simulation
- `simulate!(sim)`: Run simulation in-place
- `visualize(sim)`: Create a plot of current state
- `animate_simulation(sim; fps=30, save_path=nothing)`: Create animation
- `save_simulation(sim, filepath)`: Save to JSON
- `load_simulation(filepath)`: Load from JSON
- `export_trajectory_csv(sim, filepath)`: Export trajectory to CSV

### Utility Functions

- `total_kinetic_energy(balls)`: Calculate total kinetic energy
- `total_momentum(balls)`: Calculate total momentum vector
- `center_of_mass(balls)`: Calculate center of mass

## Running Tests

```julia
using Pkg
Pkg.test()
```

## Running Examples

```julia
include("examples/basic_simulation.jl")
```

## Physics

The package implements elastic collisions using impulse-based resolution:

1. **Ball-Ball Collisions**: Detected when distance between centers ≤ sum of radii
2. **Impulse Calculation**: Uses conservation of momentum and kinetic energy
3. **Separation**: Overlapping balls are separated to prevent tunneling
4. **Boundary Collisions**: Velocity component perpendicular to wall is reversed

The coefficient of restitution (default: 1.0) controls energy loss on collision.
