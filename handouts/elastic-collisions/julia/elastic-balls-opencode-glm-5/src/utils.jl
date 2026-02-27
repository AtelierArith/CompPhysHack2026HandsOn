using Random

function create_random_balls(n::Int; 
                            width::Real=10.0, 
                            height::Real=10.0,
                            min_radius::Real=0.2,
                            max_radius::Real=0.5,
                            max_velocity::Real=2.0,
                            colors::Vector{Symbol}=[:blue, :red, :green, :orange, :purple, :cyan])
    balls = Ball{Float64}[]
    rng = Random.GLOBAL_RNG
    
    attempts = 0
    max_attempts = n * 100
    
    while length(balls) < n && attempts < max_attempts
        attempts += 1
        
        radius = min_radius + rand(rng) * (max_radius - min_radius)
        x = radius + rand(rng) * (width - 2 * radius)
        y = radius + rand(rng) * (height - 2 * radius)
        
        vx = (rand(rng) - 0.5) * 2 * max_velocity
        vy = (rand(rng) - 0.5) * 2 * max_velocity
        
        mass = radius^2
        
        pos = Vec2D(x, y)
        valid = true
        
        for existing_ball in balls
            dist = norm(pos - existing_ball.position)
            if dist < (radius + existing_ball.radius + 0.1)
                valid = false
                break
            end
        end
        
        if valid
            color = colors[(length(balls) % length(colors)) + 1]
            ball = Ball((x, y), (vx, vy), radius, mass; 
                       color=color, id=length(balls) + 1)
            push!(balls, ball)
        end
    end
    
    if length(balls) < n
        @warn "Only created $(length(balls)) balls out of $n requested"
    end
    
    return balls
end

function kinetic_energy(ball::Ball{T}) where {T<:Real}
    0.5 * ball.mass * (ball.velocity.x^2 + ball.velocity.y^2)
end

function total_kinetic_energy(balls::Vector{<:Ball})
    sum(kinetic_energy(b) for b in balls)
end

function momentum(ball::Ball{T}) where {T<:Real}
    Vec2D(ball.mass * ball.velocity.x, ball.mass * ball.velocity.y)
end

function total_momentum(balls::Vector{<:Ball})
    px = sum(b.mass * b.velocity.x for b in balls)
    py = sum(b.mass * b.velocity.y for b in balls)
    Vec2D(px, py)
end

function center_of_mass(balls::Vector{<:Ball})
    total_mass = sum(b.mass for b in balls)
    cx = sum(b.mass * b.position.x for b in balls) / total_mass
    cy = sum(b.mass * b.position.y for b in balls) / total_mass
    Vec2D(cx, cy)
end
