using ElasticBalls
using Test

@testset "ElasticBalls.jl" begin
    # Test 1: Basic movement
    b1 = Ball([10.0, 10.0], [5.0, 0.0], 1.0, 1.0, "red")
    sim = Sim([b1], 100.0, 100.0)

    step!(sim, 1.0) # Move by 5.0
    @test b1.pos ≈ [15.0, 10.0] atol=1e-5

    # Test 2: Wall collision (Left wall)
    # Ball at x=1.0, radius=1.0. Touching wall.
    # Velocity -2.0. Expected to bounce.
    b2 = Ball([1.1, 50.0], [-5.0, 0.0], 1.0, 1.0, "blue")
    sim2 = Sim([b2], 100.0, 100.0)

    step!(sim2, 0.1)
    # pos = 1.1 - 0.5 = 0.6. Wall at 0. Radius 1.0. Overlap 0.4.
    # Logic in step!:
    # if pos - radius < 0 => pos = radius, vel *= -1
    # 0.6 - 1.0 = -0.4 < 0.
    # new pos = 1.0. new vel = 5.0.

    @test b2.pos[1] ≈ 1.0
    @test b2.vel[1] == 5.0
end
