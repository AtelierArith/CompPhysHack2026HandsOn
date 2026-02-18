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
end
