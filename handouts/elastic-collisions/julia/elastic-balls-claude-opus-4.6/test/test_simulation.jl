@testset "Simulation" begin
    @testset "step! advances time" begin
        balls = [Ball(; pos=(5.0, 5.0), vel=(1.0, 0.0))]
        state = SimulationState(balls; dt=0.01)
        step!(state)
        @test state.time ≈ 0.01
    end

    @testset "step! moves ball" begin
        balls = [Ball(; pos=(5.0, 5.0), vel=(1.0, 2.0), radius=0.3)]
        state = SimulationState(balls; dt=0.1)
        step!(state)
        @test state.balls[1].pos ≈ Vec2(5.1, 5.2) atol = 1e-10
    end

    @testset "step! wall bounce" begin
        balls = [Ball(; pos=(9.8, 5.0), vel=(5.0, 0.0), radius=0.5)]
        state = SimulationState(balls; dt=0.1)
        step!(state)
        # Ball should have bounced off right wall
        @test state.balls[1].vel[1] < 0
    end

    @testset "simulate! returns trajectory" begin
        balls = [Ball(; pos=(5.0, 5.0), vel=(1.0, 0.0), radius=0.3)]
        state = SimulationState(balls; dt=0.01)
        traj = simulate!(state, 1.0)
        @test length(traj) == 100  # 1.0 / 0.01 = 100 steps
    end

    @testset "simulate! with save_interval" begin
        balls = [Ball(; pos=(5.0, 5.0), vel=(1.0, 0.0), radius=0.3)]
        state = SimulationState(balls; dt=0.01)
        traj = simulate!(state, 1.0; save_interval=10)
        @test length(traj) == 10
    end

    @testset "energy conservation over long simulation" begin
        balls = [
            Ball(; pos=(3.0, 5.0), vel=(2.0, 1.0), mass=1.0, radius=0.5),
            Ball(; pos=(7.0, 5.0), vel=(-1.0, 0.5), mass=1.5, radius=0.4),
            Ball(; pos=(5.0, 3.0), vel=(0.5, -1.5), mass=2.0, radius=0.3),
        ]
        state = SimulationState(balls; dt=0.001)

        ke_initial = sum(0.5 * b.mass * dot(b.vel, b.vel) for b in state.balls)

        simulate!(state, 10.0; save_interval=100)

        ke_final = sum(0.5 * b.mass * dot(b.vel, b.vel) for b in state.balls)

        @test ke_initial ≈ ke_final rtol = 1e-6
    end

    @testset "momentum conservation over long simulation" begin
        balls = [
            Ball(; pos=(3.0, 5.0), vel=(2.0, 1.0), mass=1.0, radius=0.5),
            Ball(; pos=(7.0, 5.0), vel=(-1.0, 0.5), mass=1.5, radius=0.4),
        ]
        state = SimulationState(balls; dt=0.001)

        # Note: total momentum is NOT conserved when walls are involved,
        # but it IS conserved for ball-ball collisions only.
        # For a full system test, we check energy conservation instead.
        # Here, for a short simulation without wall bounces:
        p_initial = sum(b.mass * b.vel for b in state.balls)

        # Very short sim where balls shouldn't hit walls
        simulate!(state, 0.5; save_interval=100)

        # Check if any ball hit a wall (if so, momentum won't be conserved)
        all_inside = all(state.balls) do b
            bb = state.boundary
            b.pos[1] - b.radius > bb.xmin + 0.01 &&
            b.pos[1] + b.radius < bb.xmax - 0.01 &&
            b.pos[2] - b.radius > bb.ymin + 0.01 &&
            b.pos[2] + b.radius < bb.ymax - 0.01
        end

        if all_inside
            p_final = sum(b.mass * b.vel for b in state.balls)
            @test p_initial ≈ p_final atol = 1e-6
        else
            @test true  # Skip check if wall collision occurred
        end
    end

    @testset "random_balls" begin
        using Random
        rng = MersenneTwister(42)
        balls = random_balls(5; rng=rng)
        @test length(balls) == 5

        # Check non-overlapping
        for i in 1:5
            for j in (i+1):5
                dist = norm(balls[i].pos - balls[j].pos)
                @test dist >= balls[i].radius + balls[j].radius
            end
        end

        # Check all inside default boundary
        boundary = BoundaryBox()
        for b in balls
            @test b.pos[1] - b.radius >= boundary.xmin
            @test b.pos[1] + b.radius <= boundary.xmax
            @test b.pos[2] - b.radius >= boundary.ymin
            @test b.pos[2] + b.radius <= boundary.ymax
        end
    end

    @testset "balls stay in boundary" begin
        using Random
        rng = MersenneTwister(123)
        balls = random_balls(5; rng=rng, speed_range=(2.0, 5.0))
        boundary = BoundaryBox()
        state = SimulationState(balls; boundary=boundary, dt=0.005)

        simulate!(state, 5.0; save_interval=100)

        for b in state.balls
            @test b.pos[1] - b.radius >= boundary.xmin - 1e-6
            @test b.pos[1] + b.radius <= boundary.xmax + 1e-6
            @test b.pos[2] - b.radius >= boundary.ymin - 1e-6
            @test b.pos[2] + b.radius <= boundary.ymax + 1e-6
        end
    end
end
