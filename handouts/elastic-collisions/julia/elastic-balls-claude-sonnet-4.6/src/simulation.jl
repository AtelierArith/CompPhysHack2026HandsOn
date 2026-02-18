"""
    step!(state) -> SimulationState

Advance the simulation one timestep `dt`:
1. Euler-integrate all positions.
2. Resolve wall collisions for each ball.
3. Resolve all pairwise ball-ball collisions (O(n²)).
"""
function step!(state::SimulationState)
    dt = state.dt
    n  = length(state.balls)
    new_balls = Vector{Ball}(undef, n)

    # Euler integration
    for i in 1:n
        b = state.balls[i]
        new_balls[i] = Ball(b.pos + b.vel * dt, b.vel, b.mass, b.radius, b.color)
    end

    # Wall collisions
    for i in 1:n
        new_balls[i] = resolve_wall_collision(new_balls[i], state.boundary)
    end

    # Ball-ball collisions (all pairs)
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
    simulate!(state, duration) -> SimulationState

Run the simulation for `duration` time units in-place. Returns the modified state.
"""
function simulate!(state::SimulationState, duration::Real)
    nsteps = round(Int, duration / state.dt)
    for _ in 1:nsteps
        step!(state)
    end
    return state
end

"""
    random_balls(n; boundary, rng, radius_range, speed_range, mass_range) -> Vector{Ball}

Generate `n` non-overlapping balls with randomly chosen positions, velocities,
masses, and radii. Colors are evenly spaced in hue.

Raises an error if placement fails after 2000 attempts per ball.
"""
function random_balls(n::Int;
    boundary     = BoundaryBox(),
    rng          = Random.GLOBAL_RNG,
    radius_range = (0.2, 0.5),
    speed_range  = (0.5, 3.0),
    mass_range   = (0.5, 2.0),
)
    balls = Ball[]
    hues  = range(0.0, 360.0; length=n+1)[1:n]

    for i in 1:n
        color  = RGB{Float64}(HSV(hues[i], 0.85, 0.95))
        radius = radius_range[1] + rand(rng) * (radius_range[2] - radius_range[1])
        mass   = mass_range[1]   + rand(rng) * (mass_range[2]   - mass_range[1])
        speed  = speed_range[1]  + rand(rng) * (speed_range[2]  - speed_range[1])
        angle  = rand(rng) * 2π
        vel    = Vec2(speed * cos(angle), speed * sin(angle))

        placed = false
        for _ in 1:2000
            px = boundary.xmin + radius +
                 rand(rng) * (boundary.xmax - boundary.xmin - 2radius)
            py = boundary.ymin + radius +
                 rand(rng) * (boundary.ymax - boundary.ymin - 2radius)
            pos = Vec2(px, py)

            no_overlap = all(
                dot(pos - b.pos, pos - b.pos) > (radius + b.radius)^2
                for b in balls
            )
            if no_overlap
                push!(balls, Ball(pos, vel, mass, radius, color))
                placed = true
                break
            end
        end
        placed || error("Could not place ball $i after 2000 attempts. " *
                        "Try fewer balls or a larger boundary.")
    end

    return balls
end
