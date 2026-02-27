using ElasticBalls

function main()
    println("Creating random balls...")
    balls = create_random_balls(10; width=10.0, height=10.0, 
                                min_radius=0.3, max_radius=0.6,
                                max_velocity=3.0)
    
    println("Created $(length(balls)) balls")
    println("Initial kinetic energy: $(total_kinetic_energy(balls))")
    
    config = SimulationConfig(dt=0.01, max_time=5.0, 
                             width=10.0, height=10.0,
                             restitution=1.0)
    
    println("Running simulation...")
    sim = simulate(balls, config; record_history=true)
    
    println("Final kinetic energy: $(total_kinetic_energy(sim.balls))")
    
    println("Creating visualization...")
    plt = visualize(sim)
    savefig(plt, "final_state.png")
    println("Saved final state to final_state.png")
    
    println("Creating animation...")
    anim = animate_simulation(sim; fps=60)
    gif(anim, "simulation.gif"; fps=60)
    println("Saved animation to simulation.gif")
    
    println("Exporting trajectory data...")
    export_trajectory_csv(sim, "trajectory.csv")
    println("Saved trajectory to trajectory.csv")
    
    println("\nDone!")
end

main()
