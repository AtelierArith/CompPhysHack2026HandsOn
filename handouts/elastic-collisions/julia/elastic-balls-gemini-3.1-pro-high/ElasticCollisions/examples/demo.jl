using ElasticCollisions
using StaticArrays

# Set up simulation parameters
width = 100.0
height = 100.0
dt = 0.05
steps = 200

# Create some balls with different properties
b1 = Ball(SVector(20.0, 20.0), SVector(50.0, 30.0), 1.0, 5.0, "red")
b2 = Ball(SVector(80.0, 80.0), SVector(-40.0, -10.0), 2.0, 10.0, "blue")
b3 = Ball(SVector(50.0, 50.0), SVector(0.0, 60.0), 1.5, 7.5, "green")
b4 = Ball(SVector(80.0, 20.0), SVector(-30.0, 40.0), 3.0, 15.0, "orange")

balls = [b1, b2, b3, b4]

# Run the simulation and generate a GIF
println("Generating simulation GIF...")
filename = animate_collisions(balls, dt, steps, width, height; filename="demo.gif", fps=30)
println("Successfully generated animation: ", filename)
