use glam::Vec2;

#[derive(Debug, Clone)]
pub struct Ball {
    pub position: Vec2,
    pub velocity: Vec2,
    pub radius: f32,
    pub mass: f32,
}

#[derive(Debug, Clone)]
pub struct World {
    pub width: f32,
    pub height: f32,
    pub balls: Vec<Ball>,
}

impl World {
    pub fn step(&mut self, dt: f32) {
        for ball in &mut self.balls {
            ball.position += ball.velocity * dt;

            if ball.position.x - ball.radius < 0.0 {
                ball.position.x = ball.radius;
                ball.velocity.x = ball.velocity.x.abs();
            }
            if ball.position.x + ball.radius > self.width {
                ball.position.x = self.width - ball.radius;
                ball.velocity.x = -ball.velocity.x.abs();
            }
            if ball.position.y - ball.radius < 0.0 {
                ball.position.y = ball.radius;
                ball.velocity.y = ball.velocity.y.abs();
            }
            if ball.position.y + ball.radius > self.height {
                ball.position.y = self.height - ball.radius;
                ball.velocity.y = -ball.velocity.y.abs();
            }
        }

        let len = self.balls.len();
        for i in 0..len {
            for j in (i + 1)..len {
                let (left, right) = self.balls.split_at_mut(j);
                let a = &mut left[i];
                let b = &mut right[0];

                let delta = b.position - a.position;
                let min_dist = a.radius + b.radius;
                let dist_sq = delta.length_squared();
                if dist_sq > min_dist * min_dist {
                    continue;
                }

                let normal = if dist_sq > 1e-12 {
                    delta / dist_sq.sqrt()
                } else {
                    let rv = b.velocity - a.velocity;
                    if rv.length_squared() > 1e-12 {
                        rv.normalize()
                    } else {
                        Vec2::X
                    }
                };

                let rv = b.velocity - a.velocity;
                let vel_along_normal = rv.dot(normal);

                if vel_along_normal < 0.0 {
                    let inv_mass_a = 1.0 / a.mass;
                    let inv_mass_b = 1.0 / b.mass;
                    let impulse_mag = -(1.0 + 1.0) * vel_along_normal / (inv_mass_a + inv_mass_b);
                    let impulse = impulse_mag * normal;

                    a.velocity -= impulse * inv_mass_a;
                    b.velocity += impulse * inv_mass_b;
                }

                let dist = dist_sq.sqrt();
                let penetration = (min_dist - dist).max(0.0);
                if penetration > 0.0 {
                    let inv_mass_a = 1.0 / a.mass;
                    let inv_mass_b = 1.0 / b.mass;
                    let total_inv_mass = inv_mass_a + inv_mass_b;
                    if total_inv_mass > 0.0 {
                        let correction = normal * (penetration / total_inv_mass);
                        a.position -= correction * inv_mass_a;
                        b.position += correction * inv_mass_b;
                    }
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const EPS: f32 = 1e-4;

    fn kinetic_energy(world: &World) -> f32 {
        world
            .balls
            .iter()
            .map(|b| 0.5 * b.mass * b.velocity.length_squared())
            .sum()
    }

    fn momentum(world: &World) -> Vec2 {
        world
            .balls
            .iter()
            .map(|b| b.mass * b.velocity)
            .fold(Vec2::ZERO, |acc, x| acc + x)
    }

    #[test]
    fn reflects_on_vertical_wall() {
        let mut world = World {
            width: 10.0,
            height: 10.0,
            balls: vec![Ball {
                position: Vec2::new(9.0, 5.0),
                velocity: Vec2::new(3.0, 0.0),
                radius: 1.0,
                mass: 1.0,
            }],
        };

        world.step(1.0);

        assert!((world.balls[0].position.x - 9.0).abs() < EPS);
        assert!((world.balls[0].velocity.x + 3.0).abs() < EPS);
    }

    #[test]
    fn head_on_equal_mass_collision_swaps_velocities() {
        let mut world = World {
            width: 30.0,
            height: 10.0,
            balls: vec![
                Ball {
                    position: Vec2::new(10.0, 5.0),
                    velocity: Vec2::new(1.0, 0.0),
                    radius: 1.0,
                    mass: 1.0,
                },
                Ball {
                    position: Vec2::new(12.0, 5.0),
                    velocity: Vec2::new(-1.0, 0.0),
                    radius: 1.0,
                    mass: 1.0,
                },
            ],
        };

        world.step(0.0);

        assert!((world.balls[0].velocity.x + 1.0).abs() < EPS);
        assert!((world.balls[1].velocity.x - 1.0).abs() < EPS);
    }

    #[test]
    fn conserves_total_momentum_and_energy_for_ball_collision() {
        let mut world = World {
            width: 40.0,
            height: 40.0,
            balls: vec![
                Ball {
                    position: Vec2::new(10.0, 10.0),
                    velocity: Vec2::new(3.0, 1.5),
                    radius: 1.0,
                    mass: 2.0,
                },
                Ball {
                    position: Vec2::new(11.8, 10.0),
                    velocity: Vec2::new(-0.5, 0.2),
                    radius: 1.0,
                    mass: 1.0,
                },
            ],
        };

        let before_p = momentum(&world);
        let before_e = kinetic_energy(&world);

        world.step(0.0);

        let after_p = momentum(&world);
        let after_e = kinetic_energy(&world);

        assert!((before_p.x - after_p.x).abs() < 1e-3);
        assert!((before_p.y - after_p.y).abs() < 1e-3);
        assert!((before_e - after_e).abs() < 1e-3);
    }
}
