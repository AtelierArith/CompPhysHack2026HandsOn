# Plan for Elastic Collisions Simulation

## Goal
Create a Rust crate to simulate and visualize 2D elastic collisions of multiple balls.

## Technology Stack
- **Language**: Rust
- **Visualization**: `macroquad`
- **Math**: `glam` (built-in to macroquad)

## Core Components

### 1. Data Structures
- `Ball`: Position, Velocity, Radius, Mass, Color.

### 2. Physics Engine
- **Movement**: velocity-based position updates.
- **Wall Collision**: Bounce off edges.
- **Ball-Ball Collision**:
  - Distance check.
  - Static resolution (push apart).
  - Dynamic resolution (impulse response).

### 3. Features
- **Mouse Interaction**: Drag to spawn with velocity.
- **Simulation Controls**: Reset, Pause, Add random.
- **Visual Polish**: Gradient trails, FPS counter.

## Progress
- [x] Project Initialization
- [x] Basic Physics Implementation
- [x] Collision Resolution Logic
- [x] Interactive UI and Controls
- [x] Unit Tests
- [x] README and Documentation
