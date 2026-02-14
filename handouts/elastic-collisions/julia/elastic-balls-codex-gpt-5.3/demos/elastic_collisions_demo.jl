#!/usr/bin/env julia

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ElasticBalls2D
using StaticArrays
using CairoMakie

function parse_args(args)
    opts = Dict{String, String}(
        "t_end" => "6.0",
        "dt" => "0.02",
        "fps" => "50",
        "outdir" => joinpath(@__DIR__, "..", "outputs"),
        "video" => "true",
    )

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--no-video"
            opts["video"] = "false"
            i += 1
        elseif startswith(arg, "--") && i < length(args)
            key = replace(arg, "--" => "")
            opts[key] = args[i + 1]
            i += 2
        else
            error("Unrecognized argument: $arg")
        end
    end

    return (
        t_end = parse(Float64, opts["t_end"]),
        dt = parse(Float64, opts["dt"]),
        fps = parse(Int, opts["fps"]),
        outdir = opts["outdir"],
        make_video = lowercase(opts["video"]) == "true",
    )
end

function initial_balls()
    return [
        Ball(SVector(0.16, 0.19), SVector(0.45, 0.21), 0.04, 1.0),
        Ball(SVector(0.84, 0.22), SVector(-0.40, 0.17), 0.05, 1.5),
        Ball(SVector(0.24, 0.78), SVector(0.24, -0.36), 0.045, 0.9),
        Ball(SVector(0.69, 0.74), SVector(-0.28, -0.24), 0.05, 1.3),
        Ball(SVector(0.50, 0.47), SVector(0.11, 0.41), 0.035, 0.7),
    ]
end

function run_demo(; t_end::Float64, dt::Float64, fps::Int, outdir::String, make_video::Bool)
    mkpath(outdir)

    bounds = (0.0, 1.0)
    world_for_stats = World(initial_balls(); xbounds = bounds, ybounds = bounds)

    e0 = kinetic_energy(world_for_stats)
    p0 = total_momentum(world_for_stats)
    simulate!(world_for_stats, t_end)
    ef = kinetic_energy(world_for_stats)
    pf = total_momentum(world_for_stats)

    println("ElasticBalls2D demo")
    println("  balls: $(length(world_for_stats.balls))")
    println("  t_end: $(t_end)")
    println("  initial energy: $(e0)")
    println("  final energy:   $(ef)")
    println("  energy drift:   $(ef - e0)")
    println("  initial momentum: $(p0)")
    println("  final momentum:   $(pf)")
    println("  momentum delta:   $(pf - p0)")

    world_for_viz = World(initial_balls(); xbounds = bounds, ybounds = bounds)
    video_path = make_video ? joinpath(outdir, "elastic-collisions-demo.mp4") : nothing
    fig = animate(world_for_viz; t_end = t_end, dt = dt, fps = fps, trails = true, filename = video_path)

    png_path = joinpath(outdir, "elastic-collisions-demo.png")
    save(png_path, fig)
    println("  snapshot: $(png_path)")

    if make_video
        println("  video:    $(video_path)")
    else
        println("  video:    skipped (--no-video)")
    end

    return nothing
end

function main(args)
    opts = parse_args(args)
    run_demo(; t_end = opts.t_end, dt = opts.dt, fps = opts.fps, outdir = opts.outdir, make_video = opts.make_video)
end

main(ARGS)
