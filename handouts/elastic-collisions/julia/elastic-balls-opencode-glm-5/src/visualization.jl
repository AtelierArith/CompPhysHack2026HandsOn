function draw_ball!(plt, ball::Ball)
    θ = range(0, 2π, length=100)
    x = ball.position.x .+ ball.radius .* cos.(θ)
    y = ball.position.y .+ ball.radius .* sin.(θ)
    plot!(plt, x, y, seriestype=:shape, fillcolor=ball.color, 
          linecolor=ball.color, fillalpha=0.7, label=false)
end

function visualize(balls::Vector{Ball{T}}, boundary::RectBoundary{T};
                   title::String="Elastic Balls Simulation") where {T<:Real}
    plt = plot(
        xlims=(boundary.xmin, boundary.xmax),
        ylims=(boundary.ymin, boundary.ymax),
        aspect_ratio=:equal,
        title=title,
        xlabel="x",
        ylabel="y",
        legend=false,
        grid=true,
        framestyle=:box
    )
    
    for ball in balls
        draw_ball!(plt, ball)
    end
    
    return plt
end

function visualize(sim::Simulation)
    visualize(sim.balls, sim.config.boundary; 
              title="Elastic Balls - t = $(round(sim.time, digits=2))")
end

function visualize(state::SimulationState, boundary::RectBoundary)
    visualize(state.balls, boundary; 
              title="Elastic Balls - t = $(round(state.time, digits=2))")
end

function animate_simulation(sim::Simulation; fps::Int=30, 
                            save_path::Union{String,Nothing}=nothing)
    if isempty(sim.history)
        error("Simulation has no history. Run with record_history=true")
    end
    
    boundary = sim.config.boundary
    n_frames = length(sim.history)
    
    anim = @animate for (i, state) in enumerate(sim.history)
        plt = visualize(state, boundary)
        plot!(plt, title="Frame $i/$n_frames - t = $(round(state.time, digits=3))")
    end
    
    if save_path !== nothing
        gif(anim, save_path, fps=fps)
    end
    
    return anim
end

function animate_simulation!(sim::Simulation; fps::Int=30, 
                             save_path::Union{String,Nothing}=nothing)
    if !sim.record_history
        sim.record_history = true
    end
    
    if isempty(sim.history)
        simulate!(sim)
    end
    
    return animate_simulation(sim; fps=fps, save_path=save_path)
end
