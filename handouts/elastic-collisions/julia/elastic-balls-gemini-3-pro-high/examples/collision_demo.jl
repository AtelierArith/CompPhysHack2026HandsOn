using Pkg
Pkg.activate(".")

using ElasticBalls
using Colors

# Define 7 balls with various properties
# Ball(pos, vel, mass, radius, color)
balls = [
    Ball([100.0, 100.0], [200.0, 150.0], 1.0, 15.0, "red"),
    Ball([400.0, 100.0], [-150.0, 100.0], 2.0, 25.0, "blue"),
    Ball([250.0, 250.0], [50.0, -200.0], 1.5, 20.0, "green"),
    Ball([100.0, 400.0], [180.0, -120.0], 1.2, 18.0, "yellow"),
    Ball([400.0, 400.0], [-100.0, -180.0], 0.8, 12.0, "magenta"),
    Ball([50.0, 250.0], [220.0, 30.0], 1.1, 16.0, "cyan"),
    Ball([450.0, 250.0], [-190.0, -40.0], 1.4, 22.0, "orange")
]

# Create simulation environment (width, height)
sim = Sim(balls, 500.0, 500.0)

# Simulate and visualize
println("Generating animation with 7 balls...")
create_animation(sim, 300, "collision_7balls.gif"; dt=1.0/60.0, substeps=10)
println("Done! Saved to collision_7balls.gif")
