# Basic example of ElasticBalls2D
#
# Usage:
#   julia --project=. examples/basic.jl
#
# Requires a Makie backend. For interactive visualization:
#   using Pkg; Pkg.add("GLMakie")
#
# For recording (headless):
#   using Pkg; Pkg.add("CairoMakie")

using ElasticBalls2D
using Random

# Create some random balls
rng = MersenneTwister(42)
boundary = BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0)
balls = random_balls(10; boundary=boundary, rng=rng)

# Create simulation state
state = SimulationState(balls; boundary=boundary, dt=0.005)

# --- Option 1: Interactive visualization (requires GLMakie) ---
# using GLMakie
# fig = visualize(state; substeps=2)

# --- Option 2: Record to GIF (requires CairoMakie) ---
using CairoMakie
record_simulation(state, "elastic_balls.gif"; duration=5.0, framerate=30)
println("Saved elastic_balls.gif")
