"""
    are_colliding(b1::Ball, b2::Ball) -> Bool

Check if two balls are overlapping (collision detected) using squared distance.
"""
function are_colliding(b1::Ball, b2::Ball)
    dx = b1.pos - b2.pos
    dist_sq = dot(dx, dx)
    min_dist = b1.radius + b2.radius
    return dist_sq <= min_dist * min_dist
end

"""
    resolve_ball_collision(b1::Ball, b2::Ball) -> (Ball, Ball)

Resolve a perfectly elastic collision between two balls.
Returns updated balls with new velocities and separated positions.

Uses the 2D elastic collision formula:
  v1' = v1 - (2m2/(m1+m2)) * dot(v1-v2, x1-x2)/|x1-x2|^2 * (x1-x2)
"""
function resolve_ball_collision(b1::Ball, b2::Ball)
    dx = b1.pos - b2.pos
    dist_sq = dot(dx, dx)

    # Avoid division by zero for coincident balls
    if dist_sq < eps(Float64)
        return b1, b2
    end

    dv = b1.vel - b2.vel
    dvdx = dot(dv, dx)

    # Only resolve if balls are approaching each other
    if dvdx >= 0
        return b1, b2
    end

    m1 = b1.mass
    m2 = b2.mass
    total_mass = m1 + m2

    # Elastic collision velocity update
    factor = dvdx / dist_sq
    v1_new = b1.vel - (2 * m2 / total_mass) * factor * dx
    v2_new = b2.vel + (2 * m1 / total_mass) * factor * dx

    # Separate overlapping balls by inverse mass ratio
    dist = sqrt(dist_sq)
    min_dist = b1.radius + b2.radius
    overlap = min_dist - dist
    if overlap > 0
        normal = dx / dist
        separation1 = (m2 / total_mass) * overlap * normal
        separation2 = -(m1 / total_mass) * overlap * normal
        pos1_new = b1.pos + separation1
        pos2_new = b2.pos + separation2
    else
        pos1_new = b1.pos
        pos2_new = b2.pos
    end

    b1_new = Ball(pos1_new, v1_new, m1, b1.radius, b1.color)
    b2_new = Ball(pos2_new, v2_new, m2, b2.radius, b2.color)
    return b1_new, b2_new
end

"""
    resolve_wall_collision(ball::Ball, boundary::BoundaryBox) -> Ball

Reflect ball velocity and mirror position when hitting boundary walls.
"""
function resolve_wall_collision(ball::Ball, boundary::BoundaryBox)
    px, py = ball.pos
    vx, vy = ball.vel
    r = ball.radius

    # Left wall
    if px - r < boundary.xmin
        px = boundary.xmin + r + (boundary.xmin + r - px)
        vx = abs(vx)
    end
    # Right wall
    if px + r > boundary.xmax
        px = boundary.xmax - r - (px + r - boundary.xmax)
        vx = -abs(vx)
    end
    # Bottom wall
    if py - r < boundary.ymin
        py = boundary.ymin + r + (boundary.ymin + r - py)
        vy = abs(vy)
    end
    # Top wall
    if py + r > boundary.ymax
        py = boundary.ymax - r - (py + r - boundary.ymax)
        vy = -abs(vy)
    end

    Ball(Vec2(px, py), Vec2(vx, vy), ball.mass, ball.radius, ball.color)
end
