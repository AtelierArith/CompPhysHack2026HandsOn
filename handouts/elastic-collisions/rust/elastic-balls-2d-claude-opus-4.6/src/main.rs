use elastic_balls_2d::{Ball, World};
use macroquad::prelude::*;
use ::rand::Rng;

fn random_ball(width: f32, height: f32) -> Ball {
    let mut rng = ::rand::thread_rng();
    let radius = rng.gen_range(10.0..40.0);
    let pos = Vec2::new(
        rng.gen_range(radius..width - radius),
        rng.gen_range(radius..height - radius),
    );
    let vel = Vec2::new(rng.gen_range(-300.0..300.0), rng.gen_range(-300.0..300.0));
    let color = [
        rng.gen_range(0.3..1.0),
        rng.gen_range(0.3..1.0),
        rng.gen_range(0.3..1.0),
        1.0,
    ];
    Ball::new(pos, vel, radius, color)
}

#[macroquad::main("Elastic Balls 2D")]
async fn main() {
    let mut world = World::new(screen_width(), screen_height());

    for _ in 0..5 {
        let ball = random_ball(world.width, world.height);
        world.add_ball(ball);
    }

    loop {
        // Input
        if is_mouse_button_pressed(MouseButton::Left) {
            let (mx, my) = mouse_position();
            let mut ball = random_ball(world.width, world.height);
            ball.pos = Vec2::new(mx, my);
            world.add_ball(ball);
        }

        if is_key_pressed(KeyCode::Space) {
            world.paused = !world.paused;
        }

        if is_key_pressed(KeyCode::R) {
            world.clear();
            for _ in 0..5 {
                let ball = random_ball(world.width, world.height);
                world.add_ball(ball);
            }
        }

        if is_key_pressed(KeyCode::Up) {
            world.speed_multiplier = (world.speed_multiplier + 0.1).min(10.0);
        }
        if is_key_pressed(KeyCode::Down) {
            world.speed_multiplier = (world.speed_multiplier - 0.1).max(0.1);
        }

        // Resize
        world.resize(screen_width(), screen_height());

        // Update
        world.update(get_frame_time());

        // Draw
        clear_background(Color::new(0.1, 0.1, 0.15, 1.0));

        // Boundary
        draw_rectangle_lines(0.0, 0.0, world.width, world.height, 2.0, WHITE);

        // Balls
        for ball in &world.balls {
            let c = Color::new(ball.color[0], ball.color[1], ball.color[2], ball.color[3]);
            draw_circle(ball.pos.x, ball.pos.y, ball.radius, c);
            draw_circle_lines(ball.pos.x, ball.pos.y, ball.radius, 1.5, WHITE);
        }

        // HUD
        let hud = format!(
            "Balls: {}  Speed: {:.1}x  FPS: {}{}",
            world.ball_count(),
            world.speed_multiplier,
            get_fps(),
            if world.paused { "  [PAUSED]" } else { "" },
        );
        draw_text(&hud, 10.0, 24.0, 20.0, WHITE);
        draw_text(
            "Click: add ball | Space: pause | R: reset | Up/Down: speed",
            10.0,
            world.height - 10.0,
            16.0,
            Color::new(0.7, 0.7, 0.7, 1.0),
        );

        next_frame().await;
    }
}
