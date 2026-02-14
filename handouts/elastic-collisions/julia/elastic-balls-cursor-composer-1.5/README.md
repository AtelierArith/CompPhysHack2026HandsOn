# ElasticBalls2D

A Julia package for simulating and visualizing elastic collisions of multiple balls in 2D space.

## Features

- **Physics**: Perfectly elastic ball–ball and ball–wall collisions with momentum and energy conservation
- **Simulation**: Euler integration with configurable timestep and rectangular boundary
- **Visualization**: Interactive display and GIF/MP4 recording via Makie

## Installation

From the package directory:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## Quick Start

```julia
using ElasticBalls2D
using Random

# Create random non-overlapping balls
rng = MersenneTwister(42)
boundary = BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0)
balls = random_balls(10; boundary=boundary, rng=rng)

# Run simulation
state = SimulationState(balls; boundary=boundary, dt=0.005)
trajectories = simulate!(state, 5.0; save_interval=10)

# Record to GIF (requires CairoMakie)
using CairoMakie
record_simulation(state, "elastic_balls.gif"; duration=5.0, framerate=30)
```

## API

| Symbol | Description |
|--------|-------------|
| `Vec2`, `Ball`, `BoundaryBox`, `SimulationState` | Core types |
| `are_colliding`, `resolve_ball_collision`, `resolve_wall_collision` | Physics functions |
| `step!`, `simulate!`, `random_balls` | Simulation |
| `visualize`, `record_simulation` | Visualization |

## Testing

```bash
julia -e 'using Pkg; Pkg.test()'
```

## Example

Run the example script:

```bash
julia --project=. examples/basic.jl
```

This records a 5-second GIF of 10 bouncing balls to `elastic_balls.gif`.
