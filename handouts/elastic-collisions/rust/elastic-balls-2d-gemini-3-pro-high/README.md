# Elastic Collisions 2D

A Rust crate for simulating and visualizing 2D elastic collisions of multiple balls using `macroquad`.

## Features
- **Physics Engine**: Realistic 2D elastic collisions (conservation of momentum and kinetic energy).
- **Interactive Controls**:
  - **Left Click & Drag**: Spawn a ball with custom velocity vector.
  - **SPACE**: Add a new random ball.
  - **R**: Reset the simulation.
  - **P**: Pause/Resume the simulation.
  - **T**: Toggle trail effect for motion visualization.
- **Visuals**: Vibrant randomized colors, real-time FPS counter, and ball count.

## Running the Simulation

Ensure you have Rust installed. Clone the repository and run:

```bash
cargo run --release
```

## Physics Implementation

The simulation handles:
1.  **Movement**: Explicit Euler integration.
2.  **Wall Collisions**: Velocity reflection at screen boundaries.
3.  **Ball-Ball Collisions**:
    - **Detection**: Distance-based collision check.
    - **Resolution**:
        - **Static**: Position correction to prevent ball overlapping.
        - **Dynamic**: Impulse-based velocity change along the collision normal.

## Dependencies
- `macroquad`: Fast and simple 2D game library.
