function ball_to_dict(ball::Ball{T}) where {T<:Real}
    Dict(
        "id" => ball.id,
        "position" => [ball.position.x, ball.position.y],
        "velocity" => [ball.velocity.x, ball.velocity.y],
        "radius" => ball.radius,
        "mass" => ball.mass,
        "color" => String(ball.color)
    )
end

function dict_to_ball(d::Dict)
    Ball(
        (d["position"][1], d["position"][2]),
        (d["velocity"][1], d["velocity"][2]),
        d["radius"],
        d["mass"];
        color=Symbol(d["color"]),
        id=d["id"]
    )
end

function state_to_dict(state::SimulationState{T}) where {T<:Real}
    Dict(
        "time" => state.time,
        "balls" => [ball_to_dict(b) for b in state.balls]
    )
end

function dict_to_state(d::Dict)
    balls = [dict_to_ball(b) for b in d["balls"]]
    SimulationState(d["time"], balls)
end

function config_to_dict(config::SimulationConfig{T}) where {T<:Real}
    Dict(
        "dt" => config.dt,
        "max_time" => config.max_time,
        "boundary" => Dict(
            "xmin" => config.boundary.xmin,
            "xmax" => config.boundary.xmax,
            "ymin" => config.boundary.ymin,
            "ymax" => config.boundary.ymax
        ),
        "restitution" => config.restitution
    )
end

function simulation_to_dict(sim::Simulation{T}) where {T<:Real}
    Dict(
        "config" => config_to_dict(sim.config),
        "time" => sim.time,
        "balls" => [ball_to_dict(b) for b in sim.balls],
        "history" => [state_to_dict(s) for s in sim.history]
    )
end

function save_simulation(sim::Simulation, filepath::String)
    data = simulation_to_dict(sim)
    
    open(filepath, "w") do f
        print(f, JSON.json(data, 2))
    end
end

function load_simulation(filepath::String)
    data = JSON.parsefile(filepath)
    
    config_data = data["config"]
    boundary_data = config_data["boundary"]
    boundary = RectBoundary(
        boundary_data["xmin"],
        boundary_data["xmax"],
        boundary_data["ymin"],
        boundary_data["ymax"]
    )
    config = SimulationConfig(
        config_data["dt"],
        config_data["max_time"],
        boundary,
        config_data["restitution"]
    )
    
    balls = [dict_to_ball(b) for b in data["balls"]]
    history = [dict_to_state(s) for s in get(data, "history", [])]
    
    T = Float64
    sim = Simulation(config, balls, data["time"], history, !isempty(history))
    
    return sim
end

function export_trajectory_csv(sim::Simulation, filepath::String)
    if isempty(sim.history)
        error("Simulation has no history. Run with record_history=true")
    end
    
    open(filepath, "w") do f
        println(f, "time,ball_id,pos_x,pos_y,vel_x,vel_y")
        
        for state in sim.history
            for ball in state.balls
                println(f, "$(state.time),$(ball.id),",
                        "$(ball.position.x),$(ball.position.y),",
                        "$(ball.velocity.x),$(ball.velocity.y)")
            end
        end
    end
end
