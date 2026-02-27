module ElasticBalls

using StaticArrays
using Plots
using JSON

export Ball, Simulation, SimulationConfig, Vec2D, RectBoundary
export simulate!, simulate
export visualize, animate_simulation
export save_simulation, load_simulation, export_trajectory_csv
export create_random_balls
export detect_collision, resolve_collision!
export total_kinetic_energy, total_momentum, kinetic_energy, momentum, center_of_mass
export dot, norm, apply_boundary_collision
export savefig, gif

include("types.jl")
include("physics.jl")
include("boundaries.jl")
include("visualization.jl")
include("export.jl")
include("utils.jl")

end
