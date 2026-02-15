//! Elastic collision simulation for multiple balls in 2D space.
//!
//! This crate provides physics simulation for balls that collide elastically
//! with each other and with the boundaries of a rectangular world.

use macroquad::math::Vec2;
use std::f32::consts::PI;

/// A ball with position, velocity, radius, and mass.
/// Mass is proportional to area (πr²) for uniform density.
#[derive(Debug, Clone)]
pub struct Ball {
    pub pos: Vec2,
    pub vel: Vec2,
    pub radius: f32,
    pub mass: f32,
    pub color: [f32; 4],
}

impl Ball {
    /// Create a new ball. Mass is computed from radius assuming unit density.
    pub fn new(pos: Vec2, vel: Vec2, radius: f32, color: [f32; 4]) -> Self {
        Self {
            pos,
            vel,
            radius,
            mass: PI * radius * radius,
            color,
        }
    }
}

/// The simulation world containing balls and boundaries.
#[derive(Debug)]
pub struct World {
    pub balls: Vec<Ball>,
    pub width: f32,
    pub height: f32,
    pub paused: bool,
    pub speed_multiplier: f32,
}

impl World {
    /// Create a new world with the given dimensions.
    pub fn new(width: f32, height: f32) -> Self {
        Self {
            balls: Vec::new(),
            width,
            height,
            paused: false,
            speed_multiplier: 1.0,
        }
    }

    /// Add a ball to the world.
    pub fn add_ball(&mut self, ball: Ball) {
        self.balls.push(ball);
    }

    /// Remove all balls.
    pub fn clear(&mut self) {
        self.balls.clear();
    }

    /// Number of balls in the world.
    pub fn ball_count(&self) -> usize {
        self.balls.len()
    }

    /// Update world dimensions (e.g., on window resize).
    pub fn resize(&mut self, width: f32, height: f32) {
        self.width = width;
        self.height = height;
    }

    /// Advance the simulation by `dt` seconds.
    /// Uses fixed sub-stepping for numerical stability.
    pub fn update(&mut self, dt: f32) {
        if self.paused {
            return;
        }

        let total_dt = dt * self.speed_multiplier;
        let max_sub_dt = 1.0 / 120.0;
        let mut remaining = total_dt;

        while remaining > 0.0 {
            let sub_dt = remaining.min(max_sub_dt);
            remaining -= sub_dt;
            self.step(sub_dt);
        }
    }

    fn step(&mut self, dt: f32) {
        // Integrate position
        for ball in self.balls.iter_mut() {
            ball.pos += ball.vel * dt;
        }

        // Wall collisions (elastic bounce)
        for ball in self.balls.iter_mut() {
            let r = ball.radius;

            if ball.pos.x - r < 0.0 {
                ball.vel.x = ball.vel.x.abs();
                ball.pos.x = r;
            } else if ball.pos.x + r > self.width {
                ball.vel.x = -ball.vel.x.abs();
                ball.pos.x = self.width - r;
            }

            if ball.pos.y - r < 0.0 {
                ball.vel.y = ball.vel.y.abs();
                ball.pos.y = r;
            } else if ball.pos.y + r > self.height {
                ball.vel.y = -ball.vel.y.abs();
                ball.pos.y = self.height - r;
            }
        }

        // Ball-ball elastic collisions
        let len = self.balls.len();
        for i in 0..len {
            for j in (i + 1)..len {
                let diff = self.balls[j].pos - self.balls[i].pos;
                let dist = diff.length();
                let min_dist = self.balls[i].radius + self.balls[j].radius;

                if dist < min_dist && dist > 0.0 {
                    let normal = diff / dist;

                    // Relative velocity along collision normal
                    let rel_vel = self.balls[j].vel - self.balls[i].vel;
                    let vel_along_normal = rel_vel.dot(normal);

                    // Skip if balls are already separating
                    if vel_along_normal > 0.0 {
                        continue;
                    }

                    // Separate overlapping balls (position correction)
                    let overlap = min_dist - dist;
                    let m1 = self.balls[i].mass;
                    let m2 = self.balls[j].mass;
                    let total_mass = m1 + m2;
                    self.balls[i].pos -= normal * (overlap * m2 / total_mass);
                    self.balls[j].pos += normal * (overlap * m1 / total_mass);

                    // Elastic collision: exchange momentum along normal
                    // For equal-mass 1D collision: v1' = v2, v2' = v1
                    // General formula: impulse = 2 * (v2 - v1) · n / (1/m1 + 1/m2)
                    let impulse = 2.0 * vel_along_normal / total_mass;
                    self.balls[i].vel += normal * (impulse * m2);
                    self.balls[j].vel -= normal * (impulse * m1);
                }
            }
        }
    }
}
