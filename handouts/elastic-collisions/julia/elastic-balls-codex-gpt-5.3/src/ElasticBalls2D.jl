module ElasticBalls2D

using LinearAlgebra: dot
using DataStructures: BinaryMinHeap, push!, pop!, isempty
using StaticArrays: SVector
using CairoMakie

export Ball,
    World,
    Event,
    time_to_wall_collision,
    time_to_ball_collision,
    step_event!,
    simulate!,
    kinetic_energy,
    total_momentum,
    animate

mutable struct Ball
    position::SVector{2, Float64}
    velocity::SVector{2, Float64}
    radius::Float64
    mass::Float64
    version::Int
end

function Ball(position::SVector{2, <:Real}, velocity::SVector{2, <:Real}, radius::Real, mass::Real)
    radius > 0 || throw(ArgumentError("radius must be positive"))
    mass > 0 || throw(ArgumentError("mass must be positive"))
    return Ball(SVector{2, Float64}(position), SVector{2, Float64}(velocity), Float64(radius), Float64(mass), 0)
end

struct Event
    t::Float64
    kind::Symbol
    i::Int
    j::Int
    vi::Int
    vj::Int
    seq::Int
end

Base.isless(a::Event, b::Event) = (a.t < b.t) || (a.t == b.t && a.seq < b.seq)

mutable struct World
    balls::Vector{Ball}
    xbounds::Tuple{Float64, Float64}
    ybounds::Tuple{Float64, Float64}
    t::Float64
    queue::BinaryMinHeap{Event}
    next_seq::Int
    eps_time::Float64
    eps_dist::Float64
end

function World(
    balls::Vector{Ball};
    xbounds::Tuple{<:Real, <:Real} = (0.0, 1.0),
    ybounds::Tuple{<:Real, <:Real} = (0.0, 1.0),
    t0::Real = 0.0,
    eps_time::Real = 1e-12,
    eps_dist::Real = 1e-10,
)
    xb = (Float64(xbounds[1]), Float64(xbounds[2]))
    yb = (Float64(ybounds[1]), Float64(ybounds[2]))
    xb[1] < xb[2] || throw(ArgumentError("xbounds must be increasing"))
    yb[1] < yb[2] || throw(ArgumentError("ybounds must be increasing"))

    world = World(deepcopy(balls), xb, yb, Float64(t0), BinaryMinHeap{Event}(), 1, Float64(eps_time), Float64(eps_dist))
    _validate_world!(world)
    _init_events!(world)
    return world
end

function time_to_wall_collision(ball::Ball, bounds::Tuple{Float64, Float64}, axis::Int; eps::Float64 = 1e-12)
    x = ball.position[axis]
    v = ball.velocity[axis]
    r = ball.radius

    t = if v > eps
        (bounds[2] - r - x) / v
    elseif v < -eps
        (bounds[1] + r - x) / v
    else
        Inf
    end

    return t > eps ? t : Inf
end

function time_to_ball_collision(a::Ball, b::Ball; eps::Float64 = 1e-12)
    dx = b.position - a.position
    dv = b.velocity - a.velocity
    r = a.radius + b.radius

    aa = dot(dv, dv)
    aa <= eps && return Inf

    bb = 2.0 * dot(dx, dv)
    bb >= -eps && return Inf

    cc = dot(dx, dx) - r^2
    disc = bb^2 - 4.0 * aa * cc
    disc < 0.0 && return Inf

    t = (-bb - sqrt(max(0.0, disc))) / (2.0 * aa)
    return t > eps ? t : Inf
end

kinetic_energy(world::World) = sum(0.5 * b.mass * dot(b.velocity, b.velocity) for b in world.balls)

total_momentum(world::World) = foldl((acc, b) -> acc + b.mass * b.velocity, world.balls; init = SVector(0.0, 0.0))

function step_event!(world::World)
    event = _pop_valid_event!(world)
    event === nothing && return false
    _apply_event!(world, event)
    return true
end

function simulate!(world::World, t_end::Real; max_events::Int = 10^6)
    target = Float64(t_end)
    target >= world.t || throw(ArgumentError("t_end must be >= current simulation time"))

    event_count = 0
    while world.t < target - world.eps_time
        event = _pop_valid_event!(world)
        if event === nothing || event.t > target - world.eps_time
            _advance_world!(world, target - world.t)
            touched = _resolve_overlaps!(world)
            for i in unique(touched)
                _schedule_events_for_ball!(world, i)
            end
            return world
        end

        _apply_event!(world, event)
        event_count += 1
        event_count > max_events && throw(ArgumentError("max_events exceeded before reaching t_end"))
    end

    return world
end

function animate(
    world::World;
    t_end::Real = 2.0,
    dt::Real = 1 / 60,
    fps::Int = 60,
    trails::Bool = true,
    filename::Union{Nothing, AbstractString} = nothing,
)
    dt > 0 || throw(ArgumentError("dt must be positive"))
    t_end >= 0 || throw(ArgumentError("t_end must be non-negative"))

    sim = deepcopy(world)
    start_t = sim.t
    frames = collect(0.0:Float64(dt):Float64(t_end))

    fig = CairoMakie.Figure(size = (900, 700))
    ax = CairoMakie.Axis(fig[1, 1], aspect = CairoMakie.DataAspect(), xlabel = "x", ylabel = "y")
    CairoMakie.xlims!(ax, sim.xbounds...)
    CairoMakie.ylims!(ax, sim.ybounds...)

    colors = [:steelblue, :tomato, :goldenrod, :seagreen, :orchid, :slateblue, :sienna]
    centers = [CairoMakie.Observable(CairoMakie.Point2f(b.position[1], b.position[2])) for b in sim.balls]
    trails_obs = [CairoMakie.Observable([CairoMakie.Point2f(b.position[1], b.position[2])]) for b in sim.balls]

    for i in eachindex(sim.balls)
        radius = Float32(sim.balls[i].radius)
        color = colors[mod1(i, length(colors))]

        circle = CairoMakie.lift(c -> CairoMakie.Circle(c, radius), centers[i])
        CairoMakie.poly!(ax, circle, color = color)
        if trails
            CairoMakie.lines!(ax, trails_obs[i], color = (color, 0.35), linewidth = 1.5)
        end
    end

    render_frame! = function (tau::Float64)
        simulate!(sim, start_t + tau)
        for i in eachindex(sim.balls)
            b = sim.balls[i]
            p = CairoMakie.Point2f(b.position[1], b.position[2])
            centers[i][] = p
            if trails
                pts = trails_obs[i][]
                push!(pts, p)
                trails_obs[i][] = pts
            end
        end
        return nothing
    end

    if filename === nothing
        for tau in frames
            render_frame!(tau)
        end
    else
        CairoMakie.record(fig, filename, frames; framerate = fps) do tau
            render_frame!(tau)
        end
    end

    return fig
end

function _validate_world!(world::World)
    for b in world.balls
        b.radius > 0 || throw(ArgumentError("radius must be positive"))
        b.mass > 0 || throw(ArgumentError("mass must be positive"))
        world.xbounds[1] + b.radius <= b.position[1] <= world.xbounds[2] - b.radius ||
            throw(ArgumentError("ball center is outside xbounds"))
        world.ybounds[1] + b.radius <= b.position[2] <= world.ybounds[2] - b.radius ||
            throw(ArgumentError("ball center is outside ybounds"))
    end

    for i in eachindex(world.balls)
        for j in (i + 1):length(world.balls)
            bi = world.balls[i]
            bj = world.balls[j]
            d2 = dot(bj.position - bi.position, bj.position - bi.position)
            min_d = bi.radius + bj.radius - world.eps_dist
            d2 >= min_d^2 || throw(ArgumentError("initial ball overlap detected"))
        end
    end
end

function _init_events!(world::World)
    world.queue = BinaryMinHeap{Event}()
    world.next_seq = 1

    for i in eachindex(world.balls)
        _schedule_wall_events!(world, i)
    end

    for i in eachindex(world.balls)
        for j in (i + 1):length(world.balls)
            _schedule_ball_pair_event!(world, i, j)
        end
    end
end

function _pop_valid_event!(world::World)
    while !isempty(world.queue)
        event = pop!(world.queue)
        if _event_valid(world, event)
            return event
        end
    end
    return nothing
end

function _event_valid(world::World, event::Event)
    event.t >= world.t - world.eps_time || return false
    world.balls[event.i].version == event.vi || return false
    if event.j > 0
        world.balls[event.j].version == event.vj || return false
    end
    return true
end

function _apply_event!(world::World, event::Event)
    dt = max(0.0, event.t - world.t)
    _advance_world!(world, dt)
    touched = Int[]

    if event.kind == :ball_ball
        _resolve_ball_collision!(world.balls[event.i], world.balls[event.j], world.eps_dist)
        world.balls[event.i].version += 1
        world.balls[event.j].version += 1
        push!(touched, event.i, event.j)
    elseif event.kind == :wall_x
        b = world.balls[event.i]
        b.velocity = SVector(-b.velocity[1], b.velocity[2])
        xmin = world.xbounds[1] + b.radius + world.eps_dist
        xmax = world.xbounds[2] - b.radius - world.eps_dist
        x = b.velocity[1] >= 0 ? xmin : xmax
        b.position = SVector(x, b.position[2])
        b.version += 1
        push!(touched, event.i)
    elseif event.kind == :wall_y
        b = world.balls[event.i]
        b.velocity = SVector(b.velocity[1], -b.velocity[2])
        ymin = world.ybounds[1] + b.radius + world.eps_dist
        ymax = world.ybounds[2] - b.radius - world.eps_dist
        y = b.velocity[2] >= 0 ? ymin : ymax
        b.position = SVector(b.position[1], y)
        b.version += 1
        push!(touched, event.i)
    else
        throw(ArgumentError("unknown event kind: $(event.kind)"))
    end

    append!(touched, _resolve_overlaps!(world))
    for i in unique(touched)
        _schedule_events_for_ball!(world, i)
    end

    return nothing
end

function _advance_world!(world::World, dt::Float64)
    dt <= 0 && return
    for b in world.balls
        b.position = b.position + b.velocity * dt
    end
    world.t += dt
end

function _resolve_ball_collision!(a::Ball, b::Ball, eps_dist::Float64)
    delta = b.position - a.position
    dist2 = dot(delta, delta)
    n = if dist2 > eps_dist^2
        delta / sqrt(dist2)
    else
        dv = b.velocity - a.velocity
        dv2 = dot(dv, dv)
        dv2 > eps_dist^2 ? dv / sqrt(dv2) : SVector(1.0, 0.0)
    end

    changed = false
    dist = dist2 > 0 ? sqrt(dist2) : 0.0
    overlap = a.radius + b.radius - dist
    if overlap > eps_dist
        correction = (0.5 * overlap + eps_dist) * n
        a.position = a.position - correction
        b.position = b.position + correction
        changed = true
    end

    delta2 = b.position - a.position
    sep2 = dot(delta2, delta2)
    if sep2 > eps_dist^2
        sep = sqrt(sep2)
        n = delta2 / sep
        # Only exchange impulse at contact (or tiny penetration), not at a distance.
        gap = sep - (a.radius + b.radius)
        if gap <= eps_dist
            rel = a.velocity - b.velocity
            closing_speed = dot(rel, n)
            if closing_speed > eps_dist
                impulse = 2.0 * closing_speed / (1.0 / a.mass + 1.0 / b.mass)
                a.velocity = a.velocity - (impulse / a.mass) * n
                b.velocity = b.velocity + (impulse / b.mass) * n
                changed = true
            end
        end
    end

    return changed
end

function _resolve_overlaps!(world::World; max_passes::Int = 64)
    touched = Int[]

    for _ in 1:max_passes
        changed_any = false
        max_overlap = 0.0

        for i in eachindex(world.balls)
            for j in (i + 1):length(world.balls)
                bi = world.balls[i]
                bj = world.balls[j]
                dist = sqrt(dot(bj.position - bi.position, bj.position - bi.position))
                overlap = bi.radius + bj.radius - dist
                max_overlap = max(max_overlap, overlap)

                if _resolve_ball_collision!(world.balls[i], world.balls[j], world.eps_dist)
                    world.balls[i].version += 1
                    world.balls[j].version += 1
                    push!(touched, i, j)
                    changed_any = true
                end
            end
        end

        for i in eachindex(world.balls)
            b = world.balls[i]
            x = clamp(b.position[1], world.xbounds[1] + b.radius + world.eps_dist, world.xbounds[2] - b.radius - world.eps_dist)
            y = clamp(b.position[2], world.ybounds[1] + b.radius + world.eps_dist, world.ybounds[2] - b.radius - world.eps_dist)
            if x != b.position[1] || y != b.position[2]
                b.position = SVector(x, y)
                b.version += 1
                push!(touched, i)
                changed_any = true
            end
        end

        (max_overlap <= world.eps_dist && !changed_any) && break
    end

    return touched
end

function _schedule_events_for_ball!(world::World, i::Int)
    _schedule_wall_events!(world, i)

    for j in eachindex(world.balls)
        j == i && continue
        if i < j
            _schedule_ball_pair_event!(world, i, j)
        else
            _schedule_ball_pair_event!(world, j, i)
        end
    end
end

function _schedule_wall_events!(world::World, i::Int)
    b = world.balls[i]

    tx = time_to_wall_collision(b, world.xbounds, 1; eps = world.eps_time)
    if isfinite(tx)
        _push_event!(world, :wall_x, i, 0, b.version, 0, world.t + tx)
    end

    ty = time_to_wall_collision(b, world.ybounds, 2; eps = world.eps_time)
    if isfinite(ty)
        _push_event!(world, :wall_y, i, 0, b.version, 0, world.t + ty)
    end

    return nothing
end

function _schedule_ball_pair_event!(world::World, i::Int, j::Int)
    bi = world.balls[i]
    bj = world.balls[j]
    t = time_to_ball_collision(bi, bj; eps = world.eps_time)

    if isfinite(t)
        _push_event!(world, :ball_ball, i, j, bi.version, bj.version, world.t + t)
    end

    return nothing
end

function _push_event!(world::World, kind::Symbol, i::Int, j::Int, vi::Int, vj::Int, t::Float64)
    t > world.t + world.eps_time || return
    push!(world.queue, Event(t, kind, i, j, vi, vj, world.next_seq))
    world.next_seq += 1
    return nothing
end

end
