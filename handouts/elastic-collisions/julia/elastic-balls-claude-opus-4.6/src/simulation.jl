using Random

"""
    step!(state::SimulationState)

Advance simulation by one timestep. Euler-integrates positions, then resolves
wall collisions and all ball-ball collision pairs (O(n^2)).
"""
function step!(state::SimulationState)
    dt = state.dt
    n = length(state.balls)

    # Euler integration: update positions
    new_balls = Vector{Ball}(undef, n)
    for i in 1:n
        b = state.balls[i]
        new_pos = b.pos + b.vel * dt
        new_balls[i] = Ball(new_pos, b.vel, b.mass, b.radius, b.color)
    end

    # Resolve wall collisions
    for i in 1:n
        new_balls[i] = resolve_wall_collision(new_balls[i], state.boundary)
    end

    # Resolve ball-ball collisions (all pairs)
    for i in 1:n
        for j in (i+1):n
            if are_colliding(new_balls[i], new_balls[j])
                new_balls[i], new_balls[j] = resolve_ball_collision(new_balls[i], new_balls[j])
            end
        end
    end

    state.balls = new_balls
    state.time += dt
    return state
end

"""
    simulate!(state::SimulationState, duration; save_interval=1)

Run simulation for `duration` time units headlessly.
Returns a vector of trajectory snapshots (vector of ball vectors), saved every `save_interval` steps.
"""
function simulate!(state::SimulationState, duration; save_interval=1)
    nsteps = round(Int, duration / state.dt)
    trajectories = Vector{Vector{Ball}}()
    for step_idx in 1:nsteps
        step!(state)
        if step_idx % save_interval == 0
            push!(trajectories, copy(state.balls))
        end
    end
    return trajectories
end

"""
    random_balls(n::Int; boundary=BoundaryBox(), rng=Random.GLOBAL_RNG,
                 radius_range=(0.2, 0.5), speed_range=(0.5, 3.0),
                 mass_range=(0.5, 2.0))

Generate `n` non-overlapping random balls with distinct colors within the boundary.
"""
function random_balls(n::Int;
    boundary=BoundaryBox(),
    rng=Random.GLOBAL_RNG,
    radius_range=(0.2, 0.5),
    speed_range=(0.5, 3.0),
    mass_range=(0.5, 2.0),
)
    balls = Ball[]
    # Generate distinct colors using hue spacing
    hues = range(0, 360; length=n + 1)[1:n]

    max_attempts = 1000
    for i in 1:n
        color = RGB{Float64}(HSV(hues[i], 0.8, 0.9))
        radius = radius_range[1] + rand(rng) * (radius_range[2] - radius_range[1])
        mass = mass_range[1] + rand(rng) * (mass_range[2] - mass_range[1])

        # Random velocity
        speed = speed_range[1] + rand(rng) * (speed_range[2] - speed_range[1])
        angle = rand(rng) * 2π
        vel = Vec2(speed * cos(angle), speed * sin(angle))

        # Find non-overlapping position
        placed = false
        for _ in 1:max_attempts
            px = boundary.xmin + radius + rand(rng) * (boundary.xmax - boundary.xmin - 2 * radius)
            py = boundary.ymin + radius + rand(rng) * (boundary.ymax - boundary.ymin - 2 * radius)
            pos = Vec2(px, py)

            # Check overlap with existing balls
            overlapping = false
            for existing in balls
                dx = pos - existing.pos
                if dot(dx, dx) < (radius + existing.radius)^2
                    overlapping = true
                    break
                end
            end

            if !overlapping
                push!(balls, Ball(pos, vel, mass, radius, color))
                placed = true
                break
            end
        end

        placed || error("Could not place ball $i after $max_attempts attempts. Try fewer balls or larger boundary.")
    end

    return balls
end
