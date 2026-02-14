# ElasticBalls.jl

A Julia package for simulating and visualizing elastic collisions of multiple balls in 2D space.

## Installation

This package is currently in a local directory. To use it, you can activate the project environment:

```julia
using Pkg
Pkg.activate(".")
```

Ensure you have instantiated the environment:
```julia
Pkg.instantiate()
```

## Features

- Simulate multiple balls with different masses and radii.
- Handles elastic collisions between balls and with the boundary walls.
- Visualize the simulation as a GIF animation using `Luxor.jl`.

## Usage

Here is a simple example to run a simulation and generate an animation:

```julia
using ElasticBalls
using Colors

# Define balls: position, velocity, mass, radius, color
balls = [
    Ball([100.0, 100.0], [200.0, 100.0], 1.0, 20.0, "red"),
    Ball([400.0, 100.0], [-150.0, 50.0], 2.0, 30.0, "blue"),
    Ball([250.0, 250.0], [50.0, -200.0], 1.5, 25.0, "green")
]

# Create simulation environment (width, height)
sim = Sim(balls, 500.0, 500.0)

# Run simulation and create animation
# This will generate 'collision.gif' with 300 frames.
create_animation(sim, 300, "collision.gif"; dt=1.0/60.0, substeps=10)
```

## Structure

- `src/ElasticBalls.jl`: Main module.
- `src/simulation.jl`: Physics simulation logic (`Ball`, `Sim`, `step!`).
- `src/visualization.jl`: Visualization using `Luxor` (`create_animation`).
- `examples/collision_demo.jl`: Demo script.
