use macroquad::prelude::*;

#[derive(Clone, Copy, Debug)]
pub struct Ball {
    pub position: Vec2,
    pub velocity: Vec2,
    pub radius: f32,
    pub mass: f32,
    pub color: Color,
}

impl Ball {
    pub fn new(pos: Vec2, vel: Vec2, r: f32, color: Color) -> Self {
        // Assume uniform density, so mass is proportional to area (radius squared)
        // Let's use area for now: m = pi * r^2. We'll ignore pi.
        let mass = r * r;
        Self {
            position: pos,
            velocity: vel,
            radius: r,
            mass,
            color,
        }
    }

    pub fn random(screen_width: f32, screen_height: f32) -> Self {
        let radius = rand::gen_range(10.0, 30.0);
        let x = rand::gen_range(radius, screen_width - radius);
        let y = rand::gen_range(radius, screen_height - radius);
        let position = vec2(x, y);

        // Random velocity
        let speed = rand::gen_range(50.0, 150.0);
        let angle = rand::gen_range(0.0, std::f32::consts::TAU);
        let velocity = vec2(angle.cos() * speed, angle.sin() * speed);

        let color = Color::new(
            rand::gen_range(0.5, 1.0),
            rand::gen_range(0.5, 1.0),
            rand::gen_range(0.5, 1.0),
            1.0,
        );

        Self::new(position, velocity, radius, color)
    }

    pub fn update(&mut self, dt: f32, screen_width: f32, screen_height: f32) {
        self.position += self.velocity * dt;

        // Wall collisions
        if self.position.x - self.radius < 0.0 {
            self.position.x = self.radius;
            self.velocity.x *= -1.0;
        } else if self.position.x + self.radius > screen_width {
            self.position.x = screen_width - self.radius;
            self.velocity.x *= -1.0;
        }

        if self.position.y - self.radius < 0.0 {
            self.position.y = self.radius;
            self.velocity.y *= -1.0;
        } else if self.position.y + self.radius > screen_height {
            self.position.y = screen_height - self.radius;
            self.velocity.y *= -1.0;
        }
    }

    pub fn draw(&self) {
        draw_circle(self.position.x, self.position.y, self.radius, self.color);
    }
}

pub fn resolve_collision(b1: &mut Ball, b2: &mut Ball) {
    let delta = b1.position - b2.position;
    let dist_sq = delta.length_squared();
    let min_dist = b1.radius + b2.radius;

    if dist_sq < min_dist * min_dist {
        let dist = dist_sq.sqrt();

        // Prevent division by zero
        if dist < 0.0001 {
            return;
        }

        // Push apart to avoid sticking (static resolution)
        let overlap = (min_dist - dist) / 2.0;
        let normal = delta / dist;

        b1.position += normal * overlap;
        b2.position -= normal * overlap;

        // Dynamic resolution (impulse)
        let relative_velocity = b1.velocity - b2.velocity;
        let velocity_along_normal = relative_velocity.dot(normal);

        // Do not resolve if velocities are separating
        if velocity_along_normal > 0.0 {
            return;
        }

        // Perfectly elastic collision (e = 1.0)
        let restitution = 1.0;
        let j = -(1.0 + restitution) * velocity_along_normal / (1.0 / b1.mass + 1.0 / b2.mass);

        let impulse = j * normal;

        b1.velocity += impulse / b1.mass;
        b2.velocity -= impulse / b2.mass;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_initialization() {
        let b = Ball::new(vec2(0.0, 0.0), vec2(10.0, 0.0), 10.0, RED);
        assert_eq!(b.mass, 100.0);
    }

    #[test]
    fn test_collision_resolution() {
        // Head-on collision of equal mass balls
        let mut b1 = Ball::new(vec2(0.0, 0.0), vec2(10.0, 0.0), 10.0, RED);
        let mut b2 = Ball::new(vec2(20.0, 0.0), vec2(-10.0, 0.0), 10.0, BLUE); // Just touching at r=10

        // Force a slight overlap to trigger collision logic
        b2.position.x = 19.9;

        resolve_collision(&mut b1, &mut b2);

        // They should bounce back
        assert!(b1.velocity.x < 0.0);
        assert!(b2.velocity.x > 0.0, "b2 should move right");
    }
}
