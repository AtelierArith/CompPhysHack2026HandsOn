"""
    resolve_wall_collision(ball, boundary) -> Ball

Reflect the ball off any boundary wall it has penetrated. The velocity component
perpendicular to the wall is reversed, and the position is mirrored so the ball
stays inside the box.
"""
function resolve_wall_collision(ball::Ball, boundary::BoundaryBox)
    px, py = ball.pos
    vx, vy = ball.vel
    r = ball.radius

    if px - r < boundary.xmin
        px = 2*(boundary.xmin + r) - px
        vx = abs(vx)
    elseif px + r > boundary.xmax
        px = 2*(boundary.xmax - r) - px
        vx = -abs(vx)
    end

    if py - r < boundary.ymin
        py = 2*(boundary.ymin + r) - py
        vy = abs(vy)
    elseif py + r > boundary.ymax
        py = 2*(boundary.ymax - r) - py
        vy = -abs(vy)
    end

    Ball(Vec2(px, py), Vec2(vx, vy), ball.mass, ball.radius, ball.color)
end

"""
    are_colliding(b1, b2) -> Bool

Return `true` if the two balls overlap (distance < sum of radii).
Uses squared distance to avoid a square root.
"""
function are_colliding(b1::Ball, b2::Ball)
    dx = b1.pos - b2.pos
    min_dist = b1.radius + b2.radius
    return dot(dx, dx) <= min_dist * min_dist
end

"""
    resolve_ball_collision(b1, b2) -> (Ball, Ball)

Resolve a perfectly elastic 2D collision between two balls.

Returns updated balls with:
- velocities from the standard 2D elastic collision formula
- positions separated along the collision normal (proportional to inverse mass)

The collision is only resolved if the balls are approaching each other
(`dot(Δv, Δx) < 0`); otherwise the original balls are returned unchanged.
"""
function resolve_ball_collision(b1::Ball, b2::Ball)
    dx = b1.pos - b2.pos
    dist_sq = dot(dx, dx)

    # Degenerate: coincident centers — nothing we can do cleanly
    dist_sq < eps(Float64) && return b1, b2

    dv = b1.vel - b2.vel

    # Guard: only resolve if the balls are approaching each other
    dot(dv, dx) >= 0 && return b1, b2

    m1, m2 = b1.mass, b2.mass
    total_mass = m1 + m2
    factor = dot(dv, dx) / dist_sq

    v1_new = b1.vel - (2m2 / total_mass) * factor * dx
    v2_new = b2.vel + (2m1 / total_mass) * factor * dx

    # Separate overlapping positions along the collision normal
    dist = sqrt(dist_sq)
    overlap = (b1.radius + b2.radius) - dist
    if overlap > 0
        normal = dx / dist
        p1 = b1.pos + (m2 / total_mass) * overlap * normal
        p2 = b2.pos - (m1 / total_mass) * overlap * normal
    else
        p1, p2 = b1.pos, b2.pos
    end

    Ball(p1, v1_new, m1, b1.radius, b1.color),
    Ball(p2, v2_new, m2, b2.radius, b2.color)
end
