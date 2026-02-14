# ElasticBalls2D.jl

`ElasticBalls2D.jl` simulates and visualizes 2D perfectly elastic collisions for multiple balls with:
- Event-driven exact collision timing
- Reflective rectangular walls
- Per-ball mass and radius
- Makie-based plotting/animation

## Install (local development)

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## Quick Start

```julia
using ElasticBalls2D, StaticArrays

balls = [
    Ball(SVector(0.2, 0.5), SVector(1.0, 0.0), 0.05, 1.0),
    Ball(SVector(0.8, 0.5), SVector(-1.0, 0.0), 0.05, 2.0),
    Ball(SVector(0.5, 0.8), SVector(0.0, -0.4), 0.04, 0.8),
]

world = World(balls; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))
simulate!(world, 2.0)

println("t = ", world.t)
println("energy = ", kinetic_energy(world))
println("momentum = ", total_momentum(world))
```

## Animate

```julia
using ElasticBalls2D, StaticArrays

world = World([
    Ball(SVector(0.25, 0.25), SVector(0.3, 0.2), 0.04, 1.0),
    Ball(SVector(0.7, 0.65), SVector(-0.2, -0.15), 0.06, 2.0),
]; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))

fig = animate(world; t_end=3.0, dt=1/60, fps=60)
# Save animation:
# animate(world; t_end=3.0, dt=1/60, fps=60, filename="collision.mp4")
```

## Demo Script

Run the included demo:

```bash
julia --project=. demos/elastic_collisions_demo.jl --no-video
```

Generate video + snapshot into a custom output directory:

```bash
julia --project=. demos/elastic_collisions_demo.jl --outdir ./outputs --t_end 8.0 --dt 0.02 --fps 60
```

## Public API

- `Ball(position, velocity, radius, mass)`
- `World(balls; xbounds, ybounds, t0, eps_time, eps_dist)`
- `time_to_wall_collision(ball, bounds, axis)`
- `time_to_ball_collision(ball_a, ball_b)`
- `step_event!(world)`
- `simulate!(world, t_end)`
- `kinetic_energy(world)`
- `total_momentum(world)`
- `animate(world; t_end, dt, fps, trails, filename)`
