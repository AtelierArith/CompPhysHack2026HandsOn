# ElasticBalls2D Design

## Scope
Build a Julia package for accurate simulation and visualization of many 2D elastic balls with:
- Event-driven exact collision timing
- Reflective rectangular walls
- Per-ball mass and radius
- Makie-based animation

## Architecture
The package is split into four concerns:
- `Types`: `Ball`, `World`, and `Event` types
- `Physics`: exact collision-time solvers and elastic collision response
- `Engine`: event queue, invalidation, and simulation loop
- `Viz`: Makie animation helpers

`World` holds all balls, bounds, the current simulation time, tolerances, and an event queue. Events are immutable records for `:ball_ball`, `:wall_x`, and `:wall_y`. Every ball carries a version counter; event records capture versions at scheduling time. When an event is popped, version mismatch means the event is stale and skipped.

## Data Flow
1. Create world from initial state, validate radii/masses and no initial overlaps.
2. Seed queue with wall and pair collision candidates.
3. Pop earliest valid event.
4. Advance all positions exactly to event time.
5. Resolve collision with analytic elastic equations.
6. Increment versions for affected balls and schedule new candidates.
7. Repeat until requested end time.

This flow guarantees deterministic simulation for identical inputs and avoids stale-event corruption.

## Numerics
Ball-ball collision times are found from the first nonnegative root of
`||Δx + Δv t|| = r_i + r_j`, which yields a quadratic.
Reject events when discriminant is negative, relative speed is near zero, or root is nonpositive.

Wall collision times are linear in each axis using signed velocity direction and ball radius.

Resolution uses 2D impulse equations for perfectly elastic collisions with arbitrary masses. Small tolerances (`eps_time`, `eps_dist`) avoid jitter from floating-point roundoff.

## Testing Strategy
Use TDD for every behavior:
- Unit: ball-ball time solver, wall times, wall reflection, two-body impulse invariants
- Queue: stale event invalidation correctness
- Integration: deterministic replay, no penetration, bounded kinetic-energy drift
- Visualization: smoke tests for figure creation and optional recording path
