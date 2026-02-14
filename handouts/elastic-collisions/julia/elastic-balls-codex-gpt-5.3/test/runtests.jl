using Test
using ElasticBalls2D
using StaticArrays
using CairoMakie

@testset "Collision time solvers" begin
    b = Ball(SVector(0.2, 0.5), SVector(1.0, 0.0), 0.1, 1.0)
    @test isapprox(time_to_wall_collision(b, (0.0, 1.0), 1), 0.7; atol=1e-12)

    b2 = Ball(SVector(0.8, 0.5), SVector(-2.0, 0.0), 0.1, 1.0)
    @test isapprox(time_to_wall_collision(b2, (0.0, 1.0), 1), 0.35; atol=1e-12)

    a = Ball(SVector(0.2, 0.5), SVector(1.0, 0.0), 0.05, 1.0)
    c = Ball(SVector(0.8, 0.5), SVector(-1.0, 0.0), 0.05, 1.0)
    @test isapprox(time_to_ball_collision(a, c), 0.25; atol=1e-12)

    miss = Ball(SVector(0.8, 0.8), SVector(-1.0, 0.0), 0.05, 1.0)
    @test !isfinite(time_to_ball_collision(a, miss))
end

@testset "Event-driven engine invariants" begin
    balls = [
        Ball(SVector(0.2, 0.5), SVector(1.0, 0.0), 0.05, 1.0),
        Ball(SVector(0.8, 0.5), SVector(-1.0, 0.0), 0.05, 1.0),
    ]
    world = World(balls; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))
    e0 = kinetic_energy(world)
    simulate!(world, 0.26)
    @test world.balls[1].velocity[1] < 0
    @test world.balls[2].velocity[1] > 0
    @test isapprox(kinetic_energy(world), e0; atol=1e-10)

    wall_world = World([
        Ball(SVector(0.2, 0.5), SVector(-1.0, 0.0), 0.1, 1.0),
    ]; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))
    simulate!(wall_world, 0.11)
    @test wall_world.balls[1].velocity[1] > 0

    unequal = World([
        Ball(SVector(0.2, 0.4), SVector(1.0, 0.0), 0.05, 1.0),
        Ball(SVector(0.6, 0.4), SVector(0.0, 0.0), 0.05, 3.0),
    ]; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))
    simulate!(unequal, 0.31)
    @test isapprox(unequal.balls[1].velocity[1], -0.5; atol=1e-10)
    @test isapprox(unequal.balls[2].velocity[1], 0.5; atol=1e-10)
end

@testset "Determinism" begin
    init_balls = [
        Ball(SVector(0.15, 0.2), SVector(0.35, 0.22), 0.04, 1.2),
        Ball(SVector(0.6, 0.4), SVector(-0.25, 0.1), 0.06, 0.8),
        Ball(SVector(0.4, 0.8), SVector(0.12, -0.33), 0.05, 1.5),
    ]
    w1 = World(deepcopy(init_balls); xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))
    w2 = World(deepcopy(init_balls); xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))
    simulate!(w1, 1.2)
    simulate!(w2, 1.2)

    for i in eachindex(w1.balls)
        @test isapprox(w1.balls[i].position, w2.balls[i].position; atol=1e-10)
        @test isapprox(w1.balls[i].velocity, w2.balls[i].velocity; atol=1e-10)
    end
end

@testset "Visualization" begin
    world = World([
        Ball(SVector(0.25, 0.25), SVector(0.25, 0.14), 0.04, 1.0),
        Ball(SVector(0.7, 0.65), SVector(-0.22, -0.18), 0.06, 2.0),
    ]; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))

    fig = animate(world; t_end=0.5, dt=0.05, fps=20)
    @test fig isa Figure
end

@testset "Non-penetration regression" begin
    balls = [
        Ball(SVector(0.16, 0.19), SVector(0.45, 0.21), 0.04, 1.0),
        Ball(SVector(0.84, 0.22), SVector(-0.40, 0.17), 0.05, 1.5),
        Ball(SVector(0.24, 0.78), SVector(0.24, -0.36), 0.045, 0.9),
        Ball(SVector(0.69, 0.74), SVector(-0.28, -0.24), 0.05, 1.3),
        Ball(SVector(0.50, 0.47), SVector(0.11, 0.41), 0.035, 0.7),
    ]
    world = World(balls; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))

    min_clearance = Inf
    for t in 0.0:0.002:6.0
        simulate!(world, t)
        for i in eachindex(world.balls), j in (i + 1):length(world.balls)
            bi = world.balls[i]
            bj = world.balls[j]
            d = sqrt(sum((bj.position - bi.position) .^ 2)) - (bi.radius + bj.radius)
            min_clearance = min(min_clearance, d)
        end
    end

    @test min_clearance >= -1e-6
end

@testset "No impulse before contact" begin
    world = World([
        Ball(SVector(0.2, 0.5), SVector(0.1, 0.0), 0.05, 1.0),
        Ball(SVector(0.8, 0.5), SVector(-0.1, 0.0), 0.05, 1.0),
    ]; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))

    v1 = world.balls[1].velocity
    v2 = world.balls[2].velocity
    simulate!(world, 1.0) # first contact happens around t=2.5

    @test isapprox(world.balls[1].velocity, v1; atol=1e-12)
    @test isapprox(world.balls[2].velocity, v2; atol=1e-12)
end

@testset "Wall bounce separates from boundary" begin
    world = World([
        Ball(SVector(0.2, 0.5), SVector(-1.0, 0.0), 0.1, 1.0),
    ]; xbounds=(0.0, 1.0), ybounds=(0.0, 1.0))

    simulate!(world, 0.2)
    @test world.balls[1].velocity[1] > 0
    @test world.balls[1].position[1] > world.balls[1].radius
end
