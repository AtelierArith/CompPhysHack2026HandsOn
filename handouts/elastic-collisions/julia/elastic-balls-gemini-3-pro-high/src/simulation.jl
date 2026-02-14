module Simulation

using LinearAlgebra

export Ball, Sim, step!

mutable struct Ball
    pos::Vector{Float64}
    vel::Vector{Float64}
    mass::Float64
    radius::Float64
    color::String
end

struct Sim
    balls::Vector{Ball}
    width::Float64
    height::Float64
end

function step!(sim::Sim, dt::Float64)
    # Move balls
    for ball in sim.balls
        ball.pos .+= ball.vel .* dt
    end

    # Check for wall collisions
    for ball in sim.balls
        # Left wall
        if ball.pos[1] - ball.radius < 0
            ball.pos[1] = ball.radius
            ball.vel[1] *= -1
        # Right wall
        elseif ball.pos[1] + ball.radius > sim.width
            ball.pos[1] = sim.width - ball.radius
            ball.vel[1] *= -1
        end
        # Top wall
        if ball.pos[2] - ball.radius < 0
            ball.pos[2] = ball.radius
            ball.vel[2] *= -1
        # Bottom wall
        elseif ball.pos[2] + ball.radius > sim.height
            ball.pos[2] = sim.height - ball.radius
            ball.vel[2] *= -1
        end
    end

    # Check for inter-ball collisions
    n = length(sim.balls)
    for i in 1:n
        for j in (i+1):n
            b1 = sim.balls[i]
            b2 = sim.balls[j]
            dist_sq = sum(abs2, b1.pos .- b2.pos)
            dist = sqrt(dist_sq)
            radii_sum = b1.radius + b2.radius

            if dist < radii_sum
                # Collision detected
                # Safety check for distance zero to avoid NaN
                if dist < 1e-8
                    # Move slightly apart randomly or just use a default direction
                    n_vec = [1.0, 0.0]
                    dist = 1e-8
                else
                    n_vec = (b2.pos .- b1.pos) ./ dist
                end

                overlap = radii_sum - dist

                # Separate the balls to resolve overlap proportional to inverse mass
                inv_m1 = 1.0 / b1.mass
                inv_m2 = 1.0 / b2.mass
                total_inv_mass = inv_m1 + inv_m2


                # Relative velocity (1 relative to 2)
                v_rel = b1.vel .- b2.vel
                # Velocity along normal
                vn = dot(v_rel, n_vec)

                # If vn < 0, they are already moving apart
                if vn < 1e-8
                    continue
                end

                # Impulse scalar J (Elastic collision e=1)
                j = -2.0 * vn / total_inv_mass

                # Apply impulse
                impulse = j .* n_vec
                b1.vel .+= impulse .* inv_m1
                b2.vel .-= impulse .* inv_m2

                # Separate the balls to resolve overlap after velocity update
                # (This helps prevent balls from getting stuck)
                correction = n_vec .* (overlap / total_inv_mass)
                b1.pos .-= correction .* inv_m1
                b2.pos .+= correction .* inv_m2
            end
        end
    end
end

end # module
