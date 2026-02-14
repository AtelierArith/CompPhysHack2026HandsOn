@testset "Physics" begin
    @testset "are_colliding" begin
        b1 = Ball(; pos=(0.0, 0.0), radius=1.0)
        b2 = Ball(; pos=(1.5, 0.0), radius=1.0)
        @test are_colliding(b1, b2)

        b3 = Ball(; pos=(3.0, 0.0), radius=1.0)
        @test !are_colliding(b1, b3)

        # Exactly touching
        b4 = Ball(; pos=(2.0, 0.0), radius=1.0)
        @test are_colliding(b1, b4)
    end

    @testset "resolve_ball_collision - momentum conservation" begin
        b1 = Ball(; pos=(0.0, 0.0), vel=(1.0, 0.0), mass=1.0, radius=0.6)
        b2 = Ball(; pos=(1.0, 0.0), vel=(-1.0, 0.0), mass=1.0, radius=0.6)

        b1_new, b2_new = resolve_ball_collision(b1, b2)

        # Conservation of momentum: m1*v1 + m2*v2
        p_before = b1.mass * b1.vel + b2.mass * b2.vel
        p_after = b1_new.mass * b1_new.vel + b2_new.mass * b2_new.vel
        @test p_before ≈ p_after atol = 1e-10
    end

    @testset "resolve_ball_collision - energy conservation" begin
        b1 = Ball(; pos=(0.0, 0.0), vel=(2.0, 1.0), mass=1.5, radius=0.6)
        b2 = Ball(; pos=(1.0, 0.0), vel=(-1.0, 0.5), mass=2.0, radius=0.6)

        b1_new, b2_new = resolve_ball_collision(b1, b2)

        ke_before = 0.5 * b1.mass * dot(b1.vel, b1.vel) + 0.5 * b2.mass * dot(b2.vel, b2.vel)
        ke_after = 0.5 * b1_new.mass * dot(b1_new.vel, b1_new.vel) + 0.5 * b2_new.mass * dot(b2_new.vel, b2_new.vel)
        @test ke_before ≈ ke_after atol = 1e-10
    end

    @testset "resolve_ball_collision - equal mass head-on exchange" begin
        b1 = Ball(; pos=(0.0, 0.0), vel=(1.0, 0.0), mass=1.0, radius=0.6)
        b2 = Ball(; pos=(1.0, 0.0), vel=(0.0, 0.0), mass=1.0, radius=0.6)

        b1_new, b2_new = resolve_ball_collision(b1, b2)

        # Equal mass head-on: velocities should exchange
        @test b1_new.vel ≈ Vec2(0.0, 0.0) atol = 1e-10
        @test b2_new.vel ≈ Vec2(1.0, 0.0) atol = 1e-10
    end

    @testset "resolve_ball_collision - non-approaching balls" begin
        b1 = Ball(; pos=(0.0, 0.0), vel=(-1.0, 0.0), mass=1.0, radius=0.6)
        b2 = Ball(; pos=(1.0, 0.0), vel=(1.0, 0.0), mass=1.0, radius=0.6)

        b1_new, b2_new = resolve_ball_collision(b1, b2)

        # Should not change velocities for diverging balls
        @test b1_new.vel == b1.vel
        @test b2_new.vel == b2.vel
    end

    @testset "resolve_ball_collision - overlap separation" begin
        b1 = Ball(; pos=(0.0, 0.0), vel=(1.0, 0.0), mass=1.0, radius=0.6)
        b2 = Ball(; pos=(0.8, 0.0), vel=(-1.0, 0.0), mass=1.0, radius=0.6)

        b1_new, b2_new = resolve_ball_collision(b1, b2)

        dist = norm(b1_new.pos - b2_new.pos)
        @test dist >= b1.radius + b2.radius - 1e-10
    end

    @testset "resolve_wall_collision - left wall" begin
        boundary = BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0)
        b = Ball(; pos=(-0.1, 5.0), vel=(-2.0, 0.0), radius=0.5)
        b_new = resolve_wall_collision(b, boundary)
        @test b_new.vel[1] > 0  # Reflected
        @test b_new.pos[1] >= boundary.xmin + b.radius
    end

    @testset "resolve_wall_collision - right wall" begin
        boundary = BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0)
        b = Ball(; pos=(10.1, 5.0), vel=(2.0, 0.0), radius=0.5)
        b_new = resolve_wall_collision(b, boundary)
        @test b_new.vel[1] < 0  # Reflected
        @test b_new.pos[1] <= boundary.xmax - b.radius
    end

    @testset "resolve_wall_collision - bottom wall" begin
        boundary = BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0)
        b = Ball(; pos=(5.0, -0.1), vel=(0.0, -2.0), radius=0.5)
        b_new = resolve_wall_collision(b, boundary)
        @test b_new.vel[2] > 0  # Reflected
        @test b_new.pos[2] >= boundary.ymin + b.radius
    end

    @testset "resolve_wall_collision - top wall" begin
        boundary = BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0)
        b = Ball(; pos=(5.0, 10.1), vel=(0.0, 2.0), radius=0.5)
        b_new = resolve_wall_collision(b, boundary)
        @test b_new.vel[2] < 0  # Reflected
        @test b_new.pos[2] <= boundary.ymax - b.radius
    end

    @testset "resolve_wall_collision - no collision" begin
        boundary = BoundaryBox(; xmin=0.0, xmax=10.0, ymin=0.0, ymax=10.0)
        b = Ball(; pos=(5.0, 5.0), vel=(1.0, 1.0), radius=0.5)
        b_new = resolve_wall_collision(b, boundary)
        @test b_new.pos == b.pos
        @test b_new.vel == b.vel
    end
end
