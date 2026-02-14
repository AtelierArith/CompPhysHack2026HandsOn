# elastic-balls-2d

Rust crate for simulating and visualizing elastic collisions of multiple balls in 2D space.

## What it includes

- Physics library (`src/lib.rs`):
  - Ball state (position, velocity, radius, mass)
  - Rectangular world bounds
  - Perfectly elastic ball-ball collisions
  - Wall reflections
- Visualization binary (`src/bin/visualize.rs`) using `macroquad`

## Run tests

```bash
cargo test
```

## Run visualization

```bash
cargo run --bin visualize
```

Controls:

- `R`: respawn random initial state
- `Esc`: quit
