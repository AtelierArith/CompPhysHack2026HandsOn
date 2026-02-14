module ElasticBalls

include("simulation.jl")
using .Simulation

include("visualization.jl")
using .Visualization

export Ball, Sim, step!
export create_animation

end
