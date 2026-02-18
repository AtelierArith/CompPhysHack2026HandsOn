using ElasticBalls2D
using Random

# Reproducible seed
rng = MersenneTwister(42)

boundary = BoundaryBox(; xmin=0.0, xmax=12.0, ymin=0.0, ymax=12.0)
balls    = random_balls(10; boundary=boundary, rng=rng)
state    = SimulationState(balls; boundary=boundary, dt=0.005)

outfile = joinpath(@__DIR__, "elastic_balls.mp4")
println("Recording to $outfile ...")
record_simulation(state, outfile; duration=8.0, framerate=30)
println("Done! Open $outfile to view the animation.")
