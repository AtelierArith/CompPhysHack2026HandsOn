@testset "Types" begin
    @testset "Vec2" begin
        v = Vec2(1.0, 2.0)
        @test v[1] == 1.0
        @test v[2] == 2.0
        @test v isa SVector{2,Float64}
    end

    @testset "Ball construction" begin
        b = Ball(; pos=(1.0, 2.0), vel=(3.0, 4.0), mass=2.0, radius=0.5)
        @test b.pos == Vec2(1.0, 2.0)
        @test b.vel == Vec2(3.0, 4.0)
        @test b.mass == 2.0
        @test b.radius == 0.5
    end

    @testset "Ball defaults" begin
        b = Ball(; pos=(0.0, 0.0))
        @test b.vel == Vec2(0.0, 0.0)
        @test b.mass == 1.0
        @test b.radius == 0.5
        @test b.color == RGB(1.0, 0.0, 0.0)
    end

    @testset "Ball validation" begin
        @test_throws ArgumentError Ball(; pos=(0, 0), mass=-1.0)
        @test_throws ArgumentError Ball(; pos=(0, 0), mass=0.0)
        @test_throws ArgumentError Ball(; pos=(0, 0), radius=-0.5)
        @test_throws ArgumentError Ball(; pos=(0, 0), radius=0.0)
    end

    @testset "BoundaryBox construction" begin
        bb = BoundaryBox(; xmin=-5.0, xmax=5.0, ymin=-5.0, ymax=5.0)
        @test bb.xmin == -5.0
        @test bb.xmax == 5.0
        @test bb.ymin == -5.0
        @test bb.ymax == 5.0
    end

    @testset "BoundaryBox defaults" begin
        bb = BoundaryBox()
        @test bb.xmin == 0.0
        @test bb.xmax == 10.0
        @test bb.ymin == 0.0
        @test bb.ymax == 10.0
    end

    @testset "BoundaryBox validation" begin
        @test_throws ArgumentError BoundaryBox(; xmin=5.0, xmax=0.0)
        @test_throws ArgumentError BoundaryBox(; ymin=5.0, ymax=0.0)
    end

    @testset "SimulationState construction" begin
        balls = [Ball(; pos=(5.0, 5.0))]
        state = SimulationState(balls; dt=0.02)
        @test length(state.balls) == 1
        @test state.time == 0.0
        @test state.dt == 0.02
        @test state.boundary == BoundaryBox()
    end

    @testset "SimulationState validation" begin
        balls = [Ball(; pos=(5.0, 5.0))]
        @test_throws ArgumentError SimulationState(balls; dt=-0.01)
        @test_throws ArgumentError SimulationState(balls; dt=0.0)
    end
end
