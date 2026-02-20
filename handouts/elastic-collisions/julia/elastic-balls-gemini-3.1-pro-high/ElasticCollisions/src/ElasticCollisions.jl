module ElasticCollisions

using Plots
using StaticArrays
using LinearAlgebra
using ColorTypes

export Ball, simulate!, animate_collisions

"""
    Ball(r, v, mass, radius, color)

A mutable struct representing a ball in 2D space.
"""
mutable struct Ball
    r::SVector{2, Float64}
    v::SVector{2, Float64}
    mass::Float64
    radius::Float64
    color::String
end

function update_positions!(balls::Vector{Ball}, dt::Float64)
    for b in balls
        b.r += b.v * dt
    end
end

function handle_wall_collisions!(balls::Vector{Ball}, width::Float64, height::Float64)
    for b in balls
        if b.r[1] - b.radius < 0
            b.r = SVector(b.radius, b.r[2])
            b.v = SVector(-b.v[1], b.v[2])
        elseif b.r[1] + b.radius > width
            b.r = SVector(width - b.radius, b.r[2])
            b.v = SVector(-b.v[1], b.v[2])
        end

        if b.r[2] - b.radius < 0
            b.r = SVector(b.r[1], b.radius)
            b.v = SVector(b.v[1], -b.v[2])
        elseif b.r[2] + b.radius > height
            b.r = SVector(b.r[1], height - b.radius)
            b.v = SVector(b.v[1], -b.v[2])
        end
    end
end

function handle_ball_collisions!(balls::Vector{Ball})
    n_balls = length(balls)
    for i in 1:n_balls
        for j in (i+1):n_balls
            b1 = balls[i]
            b2 = balls[j]

            delta_r = b2.r - b1.r
            dist = norm(delta_r)
            min_dist = b1.radius + b2.radius

            if dist < min_dist
                # They are colliding!
                n = dist > 0 ? delta_r / dist : SVector(1.0, 0.0) # normal vector
                delta_v = b2.v - b1.v
                v_rel_n = dot(delta_v, n)

                # If they are already separating, skip
                if v_rel_n > 0
                    continue
                end

                # Resolve velocity (assuming elastic collision, e = 1)
                m1 = b1.mass
                m2 = b2.mass

                # Impulse scalar
                j_impulse = -(2 * v_rel_n) / ((1/m1) + (1/m2))

                impulse_vector = j_impulse * n
                b1.v -= (impulse_vector / m1)
                b2.v += (impulse_vector / m2)

                # Positional correction to prevent sinking/sticking
                overlap = min_dist - dist
                correction_factor = overlap / ((1/m1) + (1/m2))

                b1.r -= (correction_factor / m1) * n
                b2.r += (correction_factor / m2) * n
            end
        end
    end
end

"""
    simulate!(balls, dt, steps, width, height)

Run the simulation without visualization for a given number of steps.
"""
function simulate!(balls::Vector{Ball}, dt::Float64, steps::Int, width::Float64, height::Float64)
    for _ in 1:steps
        update_positions!(balls, dt)
        handle_wall_collisions!(balls, width, height)
        handle_ball_collisions!(balls)
    end
end

function circle_shape(x, y, r)
    θ = LinRange(0, 2π, 30)
    x .+ r.*cos.(θ), y .+ r.*sin.(θ)
end

"""
    animate_collisions(balls, dt, steps, width, height; filename="collisions.gif", fps=30)

Simulate and create a GIF animation of the balls.
"""
function animate_collisions(balls::Vector{Ball}, dt::Float64, steps::Int, width::Float64, height::Float64; filename="collisions.gif", fps=30)
    anim = @animate for step in 1:steps
        update_positions!(balls, dt)
        handle_wall_collisions!(balls, width, height)
        handle_ball_collisions!(balls)

        # Plotting
        p = plot(xlim=(0, width), ylim=(0, height), aspect_ratio=:equal, legend=false, grid=false, showaxis=false, size=(400, 400))
        for b in balls
            x, y = circle_shape(b.r[1], b.r[2], b.radius)
            plot!(p, x, y, seriestype=:shape, fillcolor=b.color, linecolor=b.color)
        end
    end

    gif(anim, filename, fps=fps)
    return filename
end

end # module
