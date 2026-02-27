function detect_collision(ball1::Ball, ball2::Ball)
    dist_vec = ball1.position - ball2.position
    dist = norm(dist_vec)
    return dist <= (ball1.radius + ball2.radius)
end

function resolve_collision!(ball1::Ball{T}, ball2::Ball{T}, restitution::T=1.0) where {T<:Real}
    dist_vec = ball1.position - ball2.position
    dist = norm(dist_vec)
    
    if dist == 0
        dist_vec = Vec2D{T}(1.0, 0.0)
        dist = one(T)
    end
    
    normal = dist_vec / dist
    
    relative_vel = ball1.velocity - ball2.velocity
    vel_along_normal = dot(relative_vel, normal)
    
    if vel_along_normal > 0
        return ball1, ball2
    end
    
    m1, m2 = ball1.mass, ball2.mass
    impulse = -(1 + restitution) * vel_along_normal / (1/m1 + 1/m2)
    
    ball1 = Ball(
        ball1.position,
        ball1.velocity + normal * (impulse / m1),
        ball1.radius,
        ball1.mass,
        ball1.color,
        ball1.id
    )
    
    ball2 = Ball(
        ball2.position,
        ball2.velocity - normal * (impulse / m2),
        ball2.radius,
        ball2.mass,
        ball2.color,
        ball2.id
    )
    
    overlap = (ball1.radius + ball2.radius) - dist
    if overlap > 0
        separation = normal * (overlap / 2 + 0.001)
        ball1 = Ball(
            ball1.position + separation,
            ball1.velocity,
            ball1.radius,
            ball1.mass,
            ball1.color,
            ball1.id
        )
        ball2 = Ball(
            ball2.position - separation,
            ball2.velocity,
            ball2.radius,
            ball2.mass,
            ball2.color,
            ball2.id
        )
    end
    
    return ball1, ball2
end

function update_position(ball::Ball{T}, dt::T) where {T<:Real}
    Ball(
        ball.position + ball.velocity * dt,
        ball.velocity,
        ball.radius,
        ball.mass,
        ball.color,
        ball.id
    )
end

function step!(sim::Simulation{T}) where {T<:Real}
    dt = sim.config.dt
    
    sim.balls = [update_position(b, dt) for b in sim.balls]
    
    sim.balls = apply_boundary_collisions(sim.balls, sim.config.boundary, sim.config.restitution)
    
    n = length(sim.balls)
    for i in 1:n
        for j in (i+1):n
            if detect_collision(sim.balls[i], sim.balls[j])
                sim.balls[i], sim.balls[j] = resolve_collision!(
                    sim.balls[i], sim.balls[j], sim.config.restitution
                )
            end
        end
    end
    
    sim.time += dt
    
    if sim.record_history
        push!(sim.history, SimulationState(sim.time, copy(sim.balls)))
    end
end

function simulate!(sim::Simulation{T}) where {T<:Real}
    while sim.time < sim.config.max_time
        step!(sim)
    end
    return sim
end

function simulate(balls::Vector{Ball{T}}, config::SimulationConfig{T};
                  record_history::Bool=true) where {T<:Real}
    sim = Simulation(balls, config; record_history=record_history)
    simulate!(sim)
    return sim
end
