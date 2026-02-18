using Test
using ElasticBalls2D
using StaticArrays
using Colors
using LinearAlgebra

@testset "ElasticBalls2D" begin
    @testset "Types" begin
        pos = Vec2(1.0, 2.0)
        vel = Vec2(0.5, -0.3)

        # Positional constructor
        b = Ball(pos, vel, 1.0, 0.5, RGB{Float64}(1.0, 0.0, 0.0))
        @test b.pos == pos
        @test b.vel == vel
        @test b.mass == 1.0
        @test b.radius == 0.5

        # Keyword constructor with defaults
        b2 = Ball(pos=Vec2(0.0, 0.0))
        @test b2.mass == 1.0
        @test b2.radius == 0.5
        @test b2.vel == Vec2(0.0, 0.0)

        # Invalid Ball
        @test_throws ArgumentError Ball(pos, vel, -1.0, 0.5, RGB{Float64}(1.0, 0.0, 0.0))
        @test_throws ArgumentError Ball(pos, vel, 1.0, 0.0, RGB{Float64}(1.0, 0.0, 0.0))

        # BoundaryBox
        box = BoundaryBox(0.0, 10.0, 0.0, 10.0)
        @test box.xmin == 0.0
        @test box.xmax == 10.0
        @test box.ymin == 0.0
        @test box.ymax == 10.0
        @test_throws ArgumentError BoundaryBox(10.0, 0.0, 0.0, 10.0)
        @test_throws ArgumentError BoundaryBox(0.0, 10.0, 5.0, 3.0)

        # BoundaryBox keyword constructor
        box2 = BoundaryBox()
        @test box2.xmin == 0.0 && box2.xmax == 10.0

        # SimulationState
        balls = [Ball(pos=Vec2(2.0, 2.0), vel=Vec2(1.0, 0.0))]
        state = SimulationState(balls)
        @test state.time == 0.0
        @test state.dt == 0.01
        @test length(state.balls) == 1
        @test_throws ArgumentError SimulationState(balls; dt=-0.01)
    end

    @testset "Wall collisions" begin
        box = BoundaryBox(0.0, 10.0, 0.0, 10.0)

        # Ball moving left, hits left wall
        b = Ball(pos=Vec2(0.3, 5.0), vel=Vec2(-2.0, 0.0), radius=0.5)
        b2 = resolve_wall_collision(b, box)
        @test b2.vel[1] > 0                         # x-velocity flipped positive
        @test b2.pos[1] >= box.xmin + b.radius      # position inside boundary

        # Ball moving right, hits right wall
        b = Ball(pos=Vec2(9.8, 5.0), vel=Vec2(2.0, 0.0), radius=0.5)
        b2 = resolve_wall_collision(b, box)
        @test b2.vel[1] < 0
        @test b2.pos[1] <= box.xmax - b.radius

        # Ball moving down, hits bottom wall
        b = Ball(pos=Vec2(5.0, 0.2), vel=Vec2(0.0, -3.0), radius=0.5)
        b2 = resolve_wall_collision(b, box)
        @test b2.vel[2] > 0
        @test b2.pos[2] >= box.ymin + b.radius

        # Ball not touching any wall — unchanged
        b = Ball(pos=Vec2(5.0, 5.0), vel=Vec2(1.0, 1.0), radius=0.5)
        b2 = resolve_wall_collision(b, box)
        @test b2.pos == b.pos
        @test b2.vel == b.vel
    end

    @testset "Ball-ball collisions" begin
        # Two overlapping balls approaching — elastic collision
        b1 = Ball(pos=Vec2(4.4, 5.0), vel=Vec2(2.0, 0.0), mass=1.0, radius=0.6,
                  color=RGB{Float64}(1.0, 0.0, 0.0))
        b2 = Ball(pos=Vec2(5.4, 5.0), vel=Vec2(-2.0, 0.0), mass=1.0, radius=0.6,
                  color=RGB{Float64}(0.0, 0.0, 1.0))
        @test are_colliding(b1, b2)

        p_before  = b1.mass * b1.vel + b2.mass * b2.vel
        ke_before = 0.5 * b1.mass * dot(b1.vel, b1.vel) +
                    0.5 * b2.mass * dot(b2.vel, b2.vel)

        b1n, b2n = resolve_ball_collision(b1, b2)

        p_after  = b1n.mass * b1n.vel + b2n.mass * b2n.vel
        ke_after = 0.5 * b1n.mass * dot(b1n.vel, b1n.vel) +
                   0.5 * b2n.mass * dot(b2n.vel, b2n.vel)

        @test p_after  ≈ p_before  atol=1e-10   # momentum conserved
        @test ke_after ≈ ke_before atol=1e-10   # kinetic energy conserved

        # Balls no longer overlap after separation
        dx = b1n.pos - b2n.pos
        @test sqrt(dot(dx, dx)) >= b1n.radius + b2n.radius - 1e-10

        # Non-colliding balls: are_colliding returns false
        b3 = Ball(pos=Vec2(0.0, 0.0), vel=Vec2(1.0, 0.0), radius=0.3,
                  color=RGB{Float64}(0.0, 1.0, 0.0))
        b4 = Ball(pos=Vec2(5.0, 5.0), vel=Vec2(-1.0, 0.0), radius=0.3,
                  color=RGB{Float64}(1.0, 0.0, 0.0))
        @test !are_colliding(b3, b4)

        # Balls moving apart: resolve does nothing (approaching guard)
        b5 = Ball(pos=Vec2(4.4, 5.0), vel=Vec2(-1.0, 0.0), mass=1.0, radius=0.6,
                  color=RGB{Float64}(1.0, 0.0, 0.0))
        b6 = Ball(pos=Vec2(5.4, 5.0), vel=Vec2(1.0, 0.0), mass=1.0, radius=0.6,
                  color=RGB{Float64}(0.0, 0.0, 1.0))
        b5n, b6n = resolve_ball_collision(b5, b6)
        @test b5n.vel == b5.vel
        @test b6n.vel == b6.vel
    end
end
