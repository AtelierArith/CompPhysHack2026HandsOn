# Plan: Elastic Balls 2D Simulation Crate

## Context

Create a Rust crate that simulates and visualizes elastic collisions of multiple balls in 2D space. The physics engine is separated from rendering for reusability.

## Architecture

```
elastic-balls-2d/
  Cargo.toml          # macroquad 0.4, rand 0.8
  src/
    lib.rs             # Physics engine (no macroquad dependency, uses macroquad::math::Vec2 directly)
    main.rs            # Rendering + interaction via macroquad
```

**Key decision**: Use `macroquad::math::Vec2` in lib.rs. While this creates a compile-time dependency on macroquad, the `math` module is lightweight and avoids any glam version mismatch issues. The physics code itself uses no rendering — only the Vec2 type.

## Implementation Steps

### Step 1: Initialize project and Cargo.toml
- `cargo init --name elastic-balls-2d`
- Dependencies: `macroquad = "0.4"`, `rand = "0.8"`

### Step 2: Physics engine (`src/lib.rs`)

**Structs:**
- `Ball` — pos (Vec2), vel (Vec2), radius (f32), mass (f32), color ([f32; 4])
  - `Ball::new(pos, vel, radius, color)` — mass = PI * r^2
- `World` — balls (Vec<Ball>), width, height, paused, speed_multiplier
  - `World::new(width, height)`
  - `World::add_ball()`, `clear()`, `ball_count()`, `resize()`
  - `World::update(dt)` — sub-stepped simulation

**Wall collisions:**
- Reflect velocity component (using `.abs()` to prevent double-reflection)
- Clamp position to stay inside boundaries

**Ball-ball collisions (O(n^2) pairwise):**
1. Detect overlap: `distance < r1 + r2`
2. Separate overlapping balls proportional to inverse mass
3. Compute impulse along collision normal (elastic, restitution = 1.0)
4. Update velocities: `v1' = v1 + (j/m1)*n`, `v2' = v2 - (j/m2)*n`
5. Skip if balls already separating (`v_rel_along_normal > 0`)

**Sub-stepping:** Cap each sub-step at 1/120s to prevent tunneling at high speed multipliers.

### Step 3: Rendering + interaction (`src/main.rs`)

**Main loop:** input -> resize -> update -> clear -> draw -> next_frame

**Drawing:**
- Balls as filled circles with white outline
- Boundary rectangle
- HUD: ball count, speed multiplier, FPS, pause state, controls help

**Input:**
- Left-click: spawn ball at cursor with random radius (10-40), velocity, and color
- Space: pause/resume
- R: reset (clear + respawn 5 initial balls)
- Up/Down: increase/decrease speed multiplier (0.1x to 10x)

**Initial state:** 5 random balls spawned on startup.

### Step 4: Build and verify
- `cargo run` — visual verification
- Check wall bouncing, ball-ball collisions, interactivity
- Verify HUD displays correctly

## Files to create/modify
- `Cargo.toml` — project config with dependencies
- `src/lib.rs` — physics engine (~150 lines)
- `src/main.rs` — rendering and interaction (~120 lines)

## Verification
1. `cargo build` — compiles without errors
2. `cargo run` — window opens, balls bounce, collisions look physically correct
3. Click to add balls, Space to pause, R to reset, Up/Down to adjust speed
4. Balls of different sizes should react proportionally (small balls bounce more)
5. No balls escape boundaries or get stuck together
