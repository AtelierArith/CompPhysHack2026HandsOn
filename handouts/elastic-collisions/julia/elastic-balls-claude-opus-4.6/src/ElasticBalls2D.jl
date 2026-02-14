module ElasticBalls2D

include("types.jl")
include("physics.jl")
include("simulation.jl")
include("visualization.jl")

export Vec2, Ball, BoundaryBox, SimulationState
export are_colliding, resolve_ball_collision, resolve_wall_collision
export step!, simulate!, random_balls
export visualize, record_simulation

end # module ElasticBalls2D
