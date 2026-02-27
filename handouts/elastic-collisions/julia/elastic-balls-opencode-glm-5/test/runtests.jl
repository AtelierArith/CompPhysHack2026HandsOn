using Test
using ElasticBalls

@testset "Vec2D Operations" begin
    v1 = Vec2D(3.0, 4.0)
    v2 = Vec2D(1.0, 2.0)
    
    @test v1 + v2 == Vec2D(4.0, 6.0)
    @test v1 - v2 == Vec2D(2.0, 2.0)
    @test v1 * 2 == Vec2D(6.0, 8.0)
    @test 2 * v1 == Vec2D(6.0, 8.0)
    @test dot(v1, v2) == 11.0
    @test norm(v1) == 5.0
end

@testset "Ball Creation" begin
    ball = Ball((1.0, 2.0), (3.0, 4.0), 0.5, 1.0; color=:red, id=1)
    
    @test ball.position.x == 1.0
    @test ball.position.y == 2.0
    @test ball.velocity.x == 3.0
    @test ball.velocity.y == 4.0
    @test ball.radius == 0.5
    @test ball.mass == 1.0
    @test ball.color == :red
    @test ball.id == 1
end

@testset "Collision Detection" begin
    ball1 = Ball((0.0, 0.0), (1.0, 0.0), 0.5, 1.0)
    ball2 = Ball((0.8, 0.0), (-1.0, 0.0), 0.5, 1.0)
    ball3 = Ball((5.0, 0.0), (0.0, 0.0), 0.5, 1.0)
    
    @test detect_collision(ball1, ball2) == true
    @test detect_collision(ball1, ball3) == false
end

@testset "Collision Resolution" begin
    ball1 = Ball((0.0, 0.0), (1.0, 0.0), 0.5, 1.0)
    ball2 = Ball((0.9, 0.0), (-1.0, 0.0), 0.5, 1.0)
    
    b1, b2 = resolve_collision!(ball1, ball2, 1.0)
    
    @test b1.velocity.x ≈ -1.0 atol=0.01
    @test b2.velocity.x ≈ 1.0 atol=0.01
end

@testset "Boundary Collisions" begin
    boundary = RectBoundary(0.0, 10.0, 0.0, 10.0)
    
    ball = Ball((-1.0, 5.0), (-1.0, 0.0), 0.5, 1.0)
    b = apply_boundary_collision(ball, boundary, 1.0)
    @test b.position.x == 0.5
    @test b.velocity.x == 1.0
    
    ball = Ball((11.0, 5.0), (1.0, 0.0), 0.5, 1.0)
    b = apply_boundary_collision(ball, boundary, 1.0)
    @test b.position.x == 9.5
    @test b.velocity.x == -1.0
end

@testset "Energy Conservation" begin
    balls = create_random_balls(5; width=10.0, height=10.0)
    
    initial_energy = total_kinetic_energy(balls)
    
    config = SimulationConfig(dt=0.001, max_time=1.0, 
                             width=10.0, height=10.0,
                             restitution=1.0)
    sim = simulate(balls, config; record_history=false)
    
    final_energy = total_kinetic_energy(sim.balls)
    
    @test initial_energy ≈ final_energy rtol=0.01
end

@testset "Momentum Conservation" begin
    balls = create_random_balls(5; width=10.0, height=10.0)
    
    initial_momentum = total_momentum(balls)
    
    config = SimulationConfig(dt=0.001, max_time=1.0, 
                             width=10.0, height=10.0,
                             restitution=1.0)
    sim = simulate(balls, config; record_history=false)
    
    final_momentum = total_momentum(sim.balls)
    
    @test initial_momentum.x ≈ final_momentum.x atol=0.1
    @test initial_momentum.y ≈ final_momentum.y atol=0.1
end

@testset "Random Ball Generation" begin
    balls = create_random_balls(10; width=10.0, height=10.0,
                                min_radius=0.3, max_radius=0.5)
    
    @test length(balls) <= 10
    @test all(b -> b.radius >= 0.3 && b.radius <= 0.5, balls)
    @test all(b -> b.position.x >= b.radius && b.position.x <= 10 - b.radius, balls)
    @test all(b -> b.position.y >= b.radius && b.position.y <= 10 - b.radius, balls)
end
