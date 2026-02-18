# ElasticBalls2D Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a Julia package `ElasticBalls2D` that simulates perfectly elastic collisions of multiple balls (variable mass & radius) in 2D space and exports the result as an MP4/GIF animation.

**Architecture:** Immutable `Ball` structs (using `StaticArrays.SVector`) live in a mutable `SimulationState`. Each timestep performs Euler integration, wall reflection, then O(n²) ball-ball collision resolution. Visualization uses `CairoMakie.record` to export animation files.

**Tech Stack:** Julia 1.x, CairoMakie, StaticArrays, Colors, LinearAlgebra, Test (stdlib)

---

### Task 1: Initialize Package Structure

**Files:**
- Create: `Project.toml`
- Create: `src/ElasticBalls2D.jl`
- Create: `test/runtests.jl`
- Create: `examples/basic_demo.jl`

**Step 1: Create Project.toml**

```toml
name = "ElasticBalls2D"
uuid = "b1e2f3a4-c5d6-7890-abcd-ef1234567890"
version = "0.1.0"

[deps]
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[compat]
julia = "1.9"
CairoMakie = "0.10, 0.11, 0.12, 0.13, 0.14, 0.15"
Colors = "0.12, 0.13"
StaticArrays = "1"

[extras]
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[targets]
test = ["Test"]
```

**Step 2: Create minimal src/ElasticBalls2D.jl**

```julia
module ElasticBalls2D

using LinearAlgebra
using Random
using StaticArrays
using Colors
using CairoMakie

include("types.jl")
include("physics.jl")
include("simulation.jl")
include("visualization.jl")

export Vec2, Ball, BoundaryBox, SimulationState
export are_colliding, resolve_ball_collision, resolve_wall_collision
export step!, simulate!, random_balls
export record_simulation

end # module
```

**Step 3: Create placeholder source files**

Create `src/types.jl`, `src/physics.jl`, `src/simulation.jl`, `src/visualization.jl` — each with just a comment `# TODO` for now.

**Step 4: Create minimal test/runtests.jl**

```julia
using Test
using ElasticBalls2D

@testset "ElasticBalls2D" begin
    @test true  # placeholder
end
```

**Step 5: Instantiate dependencies**

```bash
cd /Users/atelierarith/work/atelierarith/CompPhysHack2026HandsOn/handouts/elastic-collisions/julia/elastic-balls-claude-sonnet-4.6
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Expected: Dependencies resolve and download.

**Step 6: Run tests to verify structure**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS with 1 test.

**Step 7: Commit**

```bash
git add Project.toml src/ test/ examples/
git commit -m "chore: initialize ElasticBalls2D package structure"
```

---

### Task 2: Implement Types

**Files:**
- Modify: `src/types.jl`
- Modify: `test/runtests.jl`

**Step 1: Write failing tests for types**

Replace `test/runtests.jl` content:

```julia
using Test
using ElasticBalls2D
using StaticArrays
using Colors

@testset "ElasticBalls2D" begin
    @testset "Types" begin
        # Ball construction
        pos = Vec2(1.0, 2.0)
        vel = Vec2(0.5, -0.3)
        b = Ball(pos, vel, 1.0, 0.5, RGB{Float64}(1.0, 0.0, 0.0))
        @test b.pos == pos
        @test b.vel == vel
        @test b.mass == 1.0
        @test b.radius == 0.5

        # Ball keyword constructor
        b2 = Ball(pos=Vec2(0.0, 0.0))
        @test b2.mass == 1.0
        @test b2.radius == 0.5

        # Invalid Ball
        @test_throws ArgumentError Ball(pos, vel, -1.0, 0.5, RGB{Float64}(1.0, 0.0, 0.0))
        @test_throws ArgumentError Ball(pos, vel, 1.0, 0.0, RGB{Float64}(1.0, 0.0, 0.0))

        # BoundaryBox construction
        box = BoundaryBox(0.0, 10.0, 0.0, 10.0)
        @test box.xmin == 0.0
        @test box.xmax == 10.0
        @test_throws ArgumentError BoundaryBox(10.0, 0.0, 0.0, 10.0)

        # SimulationState
        balls = [Ball(pos=Vec2(2.0, 2.0), vel=Vec2(1.0, 0.0))]
        state = SimulationState(balls)
        @test state.time == 0.0
        @test state.dt == 0.01
        @test length(state.balls) == 1
    end
end
```

**Step 2: Run tests to verify they fail**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: FAIL — types not defined yet.

**Step 3: Implement src/types.jl**

```julia
using StaticArrays
using Colors
using LinearAlgebra

"""Stack-allocated 2D vector."""
const Vec2 = SVector{2, Float64}

"""Immutable ball with position, velocity, mass, radius, and color."""
struct Ball
    pos::Vec2
    vel::Vec2
    mass::Float64
    radius::Float64
    color::RGB{Float64}

    function Ball(pos::Vec2, vel::Vec2, mass::Float64, radius::Float64, color::RGB{Float64})
        mass > 0 || throw(ArgumentError("mass must be positive, got $mass"))
        radius > 0 || throw(ArgumentError("radius must be positive, got $radius"))
        new(pos, vel, mass, radius, color)
    end
end

"""Keyword constructor with defaults."""
function Ball(; pos, vel=Vec2(0.0, 0.0), mass=1.0, radius=0.5,
               color=RGB{Float64}(0.2, 0.6, 1.0))
    Ball(Vec2(Float64.(pos)...), Vec2(Float64.(vel)...),
         Float64(mass), Float64(radius), RGB{Float64}(color))
end

"""Rectangular simulation domain."""
struct BoundaryBox
    xmin::Float64
    xmax::Float64
    ymin::Float64
    ymax::Float64

    function BoundaryBox(xmin, xmax, ymin, ymax)
        xmin < xmax || throw(ArgumentError("xmin must be < xmax"))
        ymin < ymax || throw(ArgumentError("ymin must be < ymax"))
        new(Float64(xmin), Float64(xmax), Float64(ymin), Float64(ymax))
    end
end

BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0) =
    BoundaryBox(xmin, xmax, ymin, ymax)

"""Mutable simulation state."""
mutable struct SimulationState
    balls::Vector{Ball}
    boundary::BoundaryBox
    time::Float64
    dt::Float64

    function SimulationState(balls, boundary, time, dt)
        dt > 0 || throw(ArgumentError("dt must be positive, got $dt"))
        new(balls, boundary, Float64(time), Float64(dt))
    end
end

SimulationState(balls::Vector{Ball}; boundary=BoundaryBox(), dt=0.01) =
    SimulationState(balls, boundary, 0.0, dt)
```

**Step 4: Run tests to verify they pass**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/types.jl test/runtests.jl
git commit -m "feat: implement Ball, BoundaryBox, SimulationState types"
```

---

### Task 3: Implement Wall Collision Physics

**Files:**
- Modify: `src/physics.jl`
- Modify: `test/runtests.jl`

**Step 1: Add failing tests for wall collision**

Append to the `@testset "ElasticBalls2D"` block in `test/runtests.jl`:

```julia
    @testset "Wall collisions" begin
        box = BoundaryBox(0.0, 10.0, 0.0, 10.0)

        # Ball moving left through left wall
        b = Ball(pos=Vec2(0.3, 5.0), vel=Vec2(-2.0, 0.0), radius=0.5)
        b2 = resolve_wall_collision(b, box)
        @test b2.vel[1] > 0          # x-velocity flipped
        @test b2.pos[1] >= box.xmin + b.radius  # position inside

        # Ball moving right through right wall
        b = Ball(pos=Vec2(9.8, 5.0), vel=Vec2(2.0, 0.0), radius=0.5)
        b2 = resolve_wall_collision(b, box)
        @test b2.vel[1] < 0
        @test b2.pos[1] <= box.xmax - b.radius

        # Ball not touching wall — unchanged
        b = Ball(pos=Vec2(5.0, 5.0), vel=Vec2(1.0, 1.0), radius=0.5)
        b2 = resolve_wall_collision(b, box)
        @test b2.pos == b.pos
        @test b2.vel == b.vel
    end
```

**Step 2: Run tests to verify they fail**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: FAIL — `resolve_wall_collision` not defined.

**Step 3: Implement resolve_wall_collision in src/physics.jl**

```julia
"""
    resolve_wall_collision(ball, boundary) -> Ball

Reflect ball off boundary walls: flip the velocity component and mirror position
so the ball stays inside the box.
"""
function resolve_wall_collision(ball::Ball, boundary::BoundaryBox)
    px, py = ball.pos
    vx, vy = ball.vel
    r = ball.radius

    if px - r < boundary.xmin
        px = 2*(boundary.xmin + r) - px
        vx = abs(vx)
    elseif px + r > boundary.xmax
        px = 2*(boundary.xmax - r) - px
        vx = -abs(vx)
    end

    if py - r < boundary.ymin
        py = 2*(boundary.ymin + r) - py
        vy = abs(vy)
    elseif py + r > boundary.ymax
        py = 2*(boundary.ymax - r) - py
        vy = -abs(vy)
    end

    Ball(Vec2(px, py), Vec2(vx, vy), ball.mass, ball.radius, ball.color)
end
```

**Step 4: Run tests to verify they pass**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/physics.jl test/runtests.jl
git commit -m "feat: implement wall collision reflection"
```

---

### Task 4: Implement Ball-Ball Collision Physics

**Files:**
- Modify: `src/physics.jl`
- Modify: `test/runtests.jl`

**Step 1: Add failing tests**

Append to `test/runtests.jl`:

```julia
    @testset "Ball-ball collisions" begin
        # Head-on equal mass collision: velocities swap
        b1 = Ball(pos=Vec2(4.0, 5.0), vel=Vec2(2.0, 0.0), mass=1.0, radius=0.4,
                  color=RGB{Float64}(1.0, 0.0, 0.0))
        b2 = Ball(pos=Vec2(5.0, 5.0), vel=Vec2(-2.0, 0.0), mass=1.0, radius=0.4,
                  color=RGB{Float64}(0.0, 0.0, 1.0))
        @test are_colliding(b1, b2)   # overlapping (dist=1.0 < sum_radii=0.8... wait)

        # Make sure they are colliding: dist=1.0, sum_radii=0.8 means NOT colliding
        # Use radii=0.6 so sum=1.2 > dist=1.0
        b1 = Ball(pos=Vec2(4.0, 5.0), vel=Vec2(2.0, 0.0), mass=1.0, radius=0.6,
                  color=RGB{Float64}(1.0, 0.0, 0.0))
        b2 = Ball(pos=Vec2(5.0, 5.0), vel=Vec2(-2.0, 0.0), mass=1.0, radius=0.6,
                  color=RGB{Float64}(0.0, 0.0, 1.0))
        @test are_colliding(b1, b2)

        p_before = b1.mass * b1.vel + b2.mass * b2.vel
        ke_before = 0.5 * b1.mass * dot(b1.vel, b1.vel) + 0.5 * b2.mass * dot(b2.vel, b2.vel)

        b1n, b2n = resolve_ball_collision(b1, b2)

        p_after = b1n.mass * b1n.vel + b2n.mass * b2n.vel
        ke_after = 0.5 * b1n.mass * dot(b1n.vel, b1n.vel) + 0.5 * b2n.mass * dot(b2n.vel, b2n.vel)

        # Momentum conserved
        @test p_after ≈ p_before  atol=1e-10
        # Kinetic energy conserved (elastic)
        @test ke_after ≈ ke_before  atol=1e-10
        # Balls no longer overlap after separation
        dx = b1n.pos - b2n.pos
        dist = sqrt(dot(dx, dx))
        @test dist >= b1n.radius + b2n.radius - 1e-10

        # Non-colliding balls: unchanged
        b3 = Ball(pos=Vec2(0.0, 0.0), vel=Vec2(1.0, 0.0), radius=0.3,
                  color=RGB{Float64}(0.0, 1.0, 0.0))
        b4 = Ball(pos=Vec2(5.0, 5.0), vel=Vec2(-1.0, 0.0), radius=0.3,
                  color=RGB{Float64}(1.0, 0.0, 0.0))
        @test !are_colliding(b3, b4)
    end
```

**Step 2: Run tests to verify they fail**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: FAIL — `are_colliding`, `resolve_ball_collision` not defined.

**Step 3: Implement ball-ball collision functions in src/physics.jl**

Append to `src/physics.jl`:

```julia
"""
    are_colliding(b1, b2) -> Bool

Return true if the two balls overlap (sum of radii > distance between centers).
Uses squared distance to avoid sqrt.
"""
function are_colliding(b1::Ball, b2::Ball)
    dx = b1.pos - b2.pos
    min_dist = b1.radius + b2.radius
    return dot(dx, dx) <= min_dist * min_dist
end

"""
    resolve_ball_collision(b1, b2) -> (Ball, Ball)

Resolve a perfectly elastic 2D collision. Returns updated balls with:
- new velocities from the elastic collision formula
- positions separated so they no longer overlap

Only acts if the balls are approaching each other.
"""
function resolve_ball_collision(b1::Ball, b2::Ball)
    dx = b1.pos - b2.pos
    dist_sq = dot(dx, dx)

    # Degenerate case: coincident centers
    dist_sq < eps(Float64) && return b1, b2

    dv = b1.vel - b2.vel

    # Only resolve if approaching (dot(dv, dx) < 0)
    dot(dv, dx) >= 0 && return b1, b2

    m1, m2 = b1.mass, b2.mass
    total_mass = m1 + m2
    factor = dot(dv, dx) / dist_sq

    v1_new = b1.vel - (2m2 / total_mass) * factor * dx
    v2_new = b2.vel + (2m1 / total_mass) * factor * dx

    # Positional separation along collision normal
    dist = sqrt(dist_sq)
    overlap = (b1.radius + b2.radius) - dist
    if overlap > 0
        normal = dx / dist
        p1 = b1.pos + (m2 / total_mass) * overlap * normal
        p2 = b2.pos - (m1 / total_mass) * overlap * normal
    else
        p1, p2 = b1.pos, b2.pos
    end

    Ball(p1, v1_new, m1, b1.radius, b1.color),
    Ball(p2, v2_new, m2, b2.radius, b2.color)
end
```

**Step 4: Run tests to verify they pass**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/physics.jl test/runtests.jl
git commit -m "feat: implement ball-ball elastic collision detection and resolution"
```

---

### Task 5: Implement Simulation Loop

**Files:**
- Modify: `src/simulation.jl`
- Modify: `test/runtests.jl`

**Step 1: Add failing tests**

Append to `test/runtests.jl`:

```julia
    @testset "Simulation" begin
        using LinearAlgebra
        box = BoundaryBox(0.0, 10.0, 0.0, 10.0)
        b1 = Ball(pos=Vec2(3.0, 5.0), vel=Vec2(1.0, 0.5), mass=1.0, radius=0.3,
                  color=RGB{Float64}(1.0, 0.0, 0.0))
        b2 = Ball(pos=Vec2(7.0, 5.0), vel=Vec2(-1.0, -0.5), mass=1.0, radius=0.3,
                  color=RGB{Float64}(0.0, 0.0, 1.0))
        state = SimulationState([b1, b2]; boundary=box, dt=0.01)

        # Total momentum before (no external forces: should be conserved)
        p_init = sum(b.mass * b.vel for b in state.balls)

        simulate!(state, 2.0)  # run for 2 seconds

        p_final = sum(b.mass * b.vel for b in state.balls)
        @test p_final ≈ p_init  atol=1e-8

        # Time advanced
        @test state.time ≈ 2.0  atol=1e-10

        # random_balls produces non-overlapping balls
        balls = random_balls(5; boundary=box)
        @test length(balls) == 5
        for i in 1:5, j in (i+1):5
            dx = balls[i].pos - balls[j].pos
            dist = sqrt(dot(dx, dx))
            @test dist >= balls[i].radius + balls[j].radius - 1e-8
        end
    end
```

**Step 2: Run tests to verify they fail**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: FAIL — `simulate!`, `random_balls` not defined.

**Step 3: Implement src/simulation.jl**

```julia
"""
    step!(state) -> SimulationState

Advance simulation one timestep: integrate positions (Euler), resolve wall
collisions, then resolve all pairwise ball-ball collisions (O(n²)).
"""
function step!(state::SimulationState)
    dt = state.dt
    n = length(state.balls)
    balls = state.balls

    # Euler integration
    new_balls = Vector{Ball}(undef, n)
    for i in 1:n
        b = balls[i]
        new_balls[i] = Ball(b.pos + b.vel * dt, b.vel, b.mass, b.radius, b.color)
    end

    # Wall collisions
    for i in 1:n
        new_balls[i] = resolve_wall_collision(new_balls[i], state.boundary)
    end

    # Ball-ball collisions (all pairs)
    for i in 1:n
        for j in (i+1):n
            if are_colliding(new_balls[i], new_balls[j])
                new_balls[i], new_balls[j] = resolve_ball_collision(new_balls[i], new_balls[j])
            end
        end
    end

    state.balls = new_balls
    state.time += dt
    return state
end

"""
    simulate!(state, duration) -> SimulationState

Run simulation for `duration` time units in-place. Returns the modified state.
"""
function simulate!(state::SimulationState, duration::Real)
    nsteps = round(Int, duration / state.dt)
    for _ in 1:nsteps
        step!(state)
    end
    return state
end

"""
    random_balls(n; boundary, rng, radius_range, speed_range, mass_range) -> Vector{Ball}

Generate `n` non-overlapping random balls with evenly-spaced hue colors.
"""
function random_balls(n::Int;
    boundary  = BoundaryBox(),
    rng       = Random.GLOBAL_RNG,
    radius_range = (0.2, 0.5),
    speed_range  = (0.5, 3.0),
    mass_range   = (0.5, 2.0),
)
    balls  = Ball[]
    hues   = range(0.0, 360.0; length=n+1)[1:n]

    for i in 1:n
        color  = RGB{Float64}(HSV(hues[i], 0.85, 0.95))
        radius = radius_range[1] + rand(rng) * (radius_range[2] - radius_range[1])
        mass   = mass_range[1]   + rand(rng) * (mass_range[2]   - mass_range[1])
        speed  = speed_range[1]  + rand(rng) * (speed_range[2]  - speed_range[1])
        angle  = rand(rng) * 2π
        vel    = Vec2(speed * cos(angle), speed * sin(angle))

        placed = false
        for _ in 1:2000
            px = boundary.xmin + radius + rand(rng) * (boundary.xmax - boundary.xmin - 2radius)
            py = boundary.ymin + radius + rand(rng) * (boundary.ymax - boundary.ymin - 2radius)
            pos = Vec2(px, py)
            if all(dot(pos - b.pos, pos - b.pos) > (radius + b.radius)^2 for b in balls)
                push!(balls, Ball(pos, vel, mass, radius, color))
                placed = true
                break
            end
        end
        placed || error("Could not place ball $i — try fewer balls or a larger boundary")
    end
    return balls
end
```

**Step 4: Run tests to verify they pass**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add src/simulation.jl test/runtests.jl
git commit -m "feat: implement simulation step loop and random_balls generator"
```

---

### Task 6: Implement Visualization (MP4/GIF export)

**Files:**
- Modify: `src/visualization.jl`

No new tests — CairoMakie rendering is integration-tested via the example.

**Step 1: Implement src/visualization.jl**

```julia
using CairoMakie

"""
    record_simulation(state, filename; duration, framerate, substeps, resolution)

Simulate and record to `filename` (MP4 or GIF). Each frame advances `substeps`
simulation steps (auto-computed from `dt` and `framerate` if not given).

# Arguments
- `state`: `SimulationState` (will be mutated)
- `filename`: output path, e.g. `"simulation.mp4"` or `"animation.gif"`
- `duration`: wall-clock duration of the animation in seconds (default 5.0)
- `framerate`: frames per second (default 30)
- `substeps`: simulation steps per frame (default: `round(Int, 1/(framerate*dt))`)
- `resolution`: figure size in pixels, e.g. `(800, 800)`
"""
function record_simulation(state::SimulationState, filename::AbstractString;
    duration    = 5.0,
    framerate   = 30,
    substeps    = nothing,
    resolution  = (800, 800),
)
    boundary = state.boundary
    if substeps === nothing
        substeps = max(1, round(Int, 1.0 / (framerate * state.dt)))
    end
    nframes = round(Int, duration * framerate)

    positions = Observable(Point2f[Point2f(b.pos...) for b in state.balls])
    radii     = Observable(Float32[b.radius for b in state.balls])
    colors    = Observable([b.color for b in state.balls])

    fig = Figure(; size=resolution)
    ax  = Axis(fig[1, 1];
        aspect = DataAspect(),
        limits = (boundary.xmin, boundary.xmax, boundary.ymin, boundary.ymax),
        title  = "Elastic Balls 2D",
        xlabel = "x", ylabel = "y",
    )

    scatter!(ax, positions;
        color      = colors,
        markersize = radii,  # radius in data units
        markerspace = :data,
        marker     = Circle,
        strokewidth = 1,
        strokecolor = :black,
    )

    record(fig, filename; framerate=framerate) do io
        for _ in 1:nframes
            for _ in 1:substeps
                step!(state)
            end
            positions[] = Point2f[Point2f(b.pos...) for b in state.balls]
            radii[]     = Float32[b.radius for b in state.balls]
            colors[]    = [b.color for b in state.balls]
            recordframe!(io)
        end
    end

    return filename
end
```

**Step 2: Run existing tests to make sure nothing broke**

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS.

**Step 3: Commit**

```bash
git add src/visualization.jl
git commit -m "feat: implement CairoMakie animation export (MP4/GIF)"
```

---

### Task 7: Create Example Script and Verify End-to-End

**Files:**
- Modify: `examples/basic_demo.jl`

**Step 1: Write examples/basic_demo.jl**

```julia
using ElasticBalls2D
using Random

# Reproducible
rng = MersenneTwister(42)

boundary = BoundaryBox(; xmin=0.0, xmax=12.0, ymin=0.0, ymax=12.0)
balls    = random_balls(10; boundary=boundary, rng=rng)
state    = SimulationState(balls; boundary=boundary, dt=0.005)

outfile = joinpath(@__DIR__, "elastic_balls.mp4")
println("Recording to $outfile ...")
record_simulation(state, outfile; duration=8.0, framerate=30)
println("Done! Open $outfile to view the animation.")
```

**Step 2: Run the example end-to-end**

```bash
julia --project=. examples/basic_demo.jl
```

Expected: MP4 file created at `examples/elastic_balls.mp4`. Inspect visually.

**Step 3: Commit**

```bash
git add examples/basic_demo.jl
git commit -m "feat: add basic_demo example for end-to-end verification"
```

---

## Summary

| Task | What it delivers |
|------|-----------------|
| 1 | Package scaffold + Pkg.instantiate |
| 2 | `Ball`, `BoundaryBox`, `SimulationState` types with validation |
| 3 | Wall-reflection physics (tested) |
| 4 | Ball-ball elastic collision (momentum + KE conserved, tested) |
| 5 | Simulation loop + `random_balls` generator (tested) |
| 6 | CairoMakie MP4/GIF export |
| 7 | End-to-end example |
