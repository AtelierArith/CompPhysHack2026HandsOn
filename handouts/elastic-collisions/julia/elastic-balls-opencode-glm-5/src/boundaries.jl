function apply_boundary_collision(ball::Ball{T}, boundary::RectBoundary{T}, 
                                   restitution::T=1.0) where {T<:Real}
    pos = ball.position
    vel = ball.velocity
    r = ball.radius
    
    new_pos = pos
    new_vel = vel
    
    if pos.x - r < boundary.xmin
        new_pos = Vec2D{T}(boundary.xmin + r, pos.y)
        new_vel = Vec2D{T}(-vel.x * restitution, vel.y)
    elseif pos.x + r > boundary.xmax
        new_pos = Vec2D{T}(boundary.xmax - r, pos.y)
        new_vel = Vec2D{T}(-vel.x * restitution, vel.y)
    end
    
    if pos.y - r < boundary.ymin
        new_pos = Vec2D{T}(new_pos.x, boundary.ymin + r)
        new_vel = Vec2D{T}(new_vel.x, -vel.y * restitution)
    elseif pos.y + r > boundary.ymax
        new_pos = Vec2D{T}(new_pos.x, boundary.ymax - r)
        new_vel = Vec2D{T}(new_vel.x, -vel.y * restitution)
    end
    
    return Ball(new_pos, new_vel, ball.radius, ball.mass, ball.color, ball.id)
end

function apply_boundary_collisions(balls::Vector{Ball{T}}, boundary::RectBoundary{T},
                                   restitution::T=1.0) where {T<:Real}
    [apply_boundary_collision(b, boundary, restitution) for b in balls]
end
