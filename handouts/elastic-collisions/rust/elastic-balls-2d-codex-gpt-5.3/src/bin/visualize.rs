use ::glam::Vec2;
use elastic_balls_2d::{Ball, World};
use macroquad::prelude::*;
use macroquad::rand::gen_range;

const WIDTH: f32 = 1000.0;
const HEIGHT: f32 = 700.0;
const BALL_COUNT: usize = 36;

fn random_color() -> Color {
    Color::new(
        gen_range(0.2, 0.95),
        gen_range(0.2, 0.95),
        gen_range(0.2, 0.95),
        1.0,
    )
}

fn random_world() -> (World, Vec<Color>) {
    let mut balls = Vec::with_capacity(BALL_COUNT);
    let mut colors = Vec::with_capacity(BALL_COUNT);

    for _ in 0..BALL_COUNT {
        let radius = gen_range(8.0, 16.0);
        let mass = radius * radius;

        let mut placed = false;
        for _ in 0..200 {
            let position = Vec2::new(
                gen_range(radius, WIDTH - radius),
                gen_range(radius, HEIGHT - radius),
            );

            let overlaps = balls.iter().any(|b: &Ball| {
                (b.position - position).length_squared() < (b.radius + radius).powi(2)
            });

            if overlaps {
                continue;
            }

            let velocity = Vec2::new(gen_range(-180.0, 180.0), gen_range(-180.0, 180.0));
            balls.push(Ball {
                position,
                velocity,
                radius,
                mass,
            });
            colors.push(random_color());
            placed = true;
            break;
        }

        if !placed {
            let position = Vec2::new(
                gen_range(radius, WIDTH - radius),
                gen_range(radius, HEIGHT - radius),
            );
            balls.push(Ball {
                position,
                velocity: Vec2::new(gen_range(-180.0, 180.0), gen_range(-180.0, 180.0)),
                radius,
                mass,
            });
            colors.push(random_color());
        }
    }

    (
        World {
            width: WIDTH,
            height: HEIGHT,
            balls,
        },
        colors,
    )
}

#[macroquad::main("Elastic Balls 2D")]
async fn main() {
    let (mut world, mut colors) = random_world();

    loop {
        let dt = get_frame_time().min(1.0 / 30.0);
        world.step(dt);

        clear_background(Color::from_rgba(14, 18, 25, 255));
        draw_rectangle_lines(
            0.0,
            0.0,
            WIDTH,
            HEIGHT,
            2.0,
            Color::from_rgba(120, 140, 170, 255),
        );

        for (idx, ball) in world.balls.iter().enumerate() {
            draw_circle(ball.position.x, ball.position.y, ball.radius, colors[idx]);
        }

        draw_text(
            "R: respawn   ESC: quit",
            16.0,
            HEIGHT - 12.0,
            24.0,
            Color::from_rgba(220, 226, 236, 255),
        );

        if is_key_pressed(KeyCode::R) {
            let (new_world, new_colors) = random_world();
            world = new_world;
            colors = new_colors;
        }

        if is_key_pressed(KeyCode::Escape) {
            break;
        }

        next_frame().await;
    }
}
