use macroquad::prelude::*;

mod sim;
use sim::Ball;

fn window_conf() -> Conf {
    Conf {
        window_title: "Elastic Collisions".to_owned(),
        window_width: 800,
        window_height: 600,
        ..Default::default()
    }
}

#[macroquad::main(window_conf)]
async fn main() {
    let mut balls = Vec::new();
    let mut click_start: Option<Vec2> = None;
    let mut show_trails = false;
    let mut paused = false;

    // Create some initial random balls
    for _ in 0..15 {
        balls.push(Ball::random(screen_width(), screen_height()));
    }

    loop {
        if !show_trails {
            clear_background(BLACK);
        } else {
            // Draw a semi-transparent rectangle to fade trails
            draw_rectangle(0.0, 0.0, screen_width(), screen_height(), Color::new(0.0, 0.0, 0.0, 0.1));
        }

        let dt = get_frame_time();
        let (width, height) = (screen_width(), screen_height());

        if !paused {
            // Update positions
            for ball in &mut balls {
                ball.update(dt, width, height);
            }

            // Handle collisions
            for i in 0..balls.len() {
                let (left, right) = balls.split_at_mut(i + 1);
                let b1 = &mut left[i];
                for b2 in right {
                    sim::resolve_collision(b1, b2);
                }
            }
        }

        // Draw balls
        for ball in &balls {
            ball.draw();
        }

        // Mouse interaction for spawning
        if is_mouse_button_pressed(MouseButton::Left) {
            click_start = Some(mouse_position().into());
        }

        if let Some(start) = click_start {
            let current: Vec2 = mouse_position().into();
            draw_line(start.x, start.y, current.x, current.y, 2.0, WHITE);

            if is_mouse_button_released(MouseButton::Left) {
                let velocity = (start - current) * 2.0; // Velocity based on drag distance
                let radius = rand::gen_range(10.0, 30.0);
                let color = Color::new(rand::gen_range(0.5, 1.0), rand::gen_range(0.5, 1.0), rand::gen_range(0.5, 1.0), 1.0);
                balls.push(Ball::new(start, velocity, radius, color));
                click_start = None;
            }
        }

        // UI
        draw_text(&format!("FPS: {}", get_fps()), 10.0, 20.0, 20.0, WHITE);
        draw_text(&format!("Balls: {}", balls.len()), 10.0, 40.0, 20.0, WHITE);
        draw_text("Controls:", 10.0, 70.0, 18.0, LIGHTGRAY);
        draw_text("- Left Click & Drag: Spawn ball with velocity", 20.0, 90.0, 16.0, LIGHTGRAY);
        draw_text("- SPACE: Add random ball", 20.0, 110.0, 16.0, LIGHTGRAY);
        draw_text("- R: Reset", 20.0, 130.0, 16.0, LIGHTGRAY);
        draw_text("- P: Pause/Resume", 20.0, 150.0, 16.0, LIGHTGRAY);
        draw_text("- T: Toggle Trails", 20.0, 170.0, 16.0, LIGHTGRAY);

        if is_key_pressed(KeyCode::Space) {
            balls.push(Ball::random(width, height));
        }

        if is_key_pressed(KeyCode::R) {
            balls.clear();
            for _ in 0..15 {
                balls.push(Ball::random(width, height));
            }
        }

        if is_key_pressed(KeyCode::P) {
            paused = !paused;
        }

        if is_key_pressed(KeyCode::T) {
            show_trails = !show_trails;
        }

        next_frame().await
    }
}
