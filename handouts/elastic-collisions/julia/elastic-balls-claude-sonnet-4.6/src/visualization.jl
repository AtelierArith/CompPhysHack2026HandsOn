using CairoMakie

"""
    record_simulation(state, filename; duration, framerate, substeps, resolution)

Simulate and record to `filename` (MP4 or GIF).

Each animation frame advances the simulation by `substeps` steps. If `substeps`
is not given it is auto-computed so that one frame of wall-clock animation
corresponds to one frame of simulation time (i.e. `1 / (framerate * dt)` steps).

# Arguments
- `state::SimulationState` — will be mutated during recording
- `filename::AbstractString` — output path (e.g. `"out.mp4"` or `"out.gif"`)
- `duration` — animation duration in seconds (default `5.0`)
- `framerate` — frames per second (default `30`)
- `substeps` — simulation steps per frame (default: auto)
- `resolution` — figure size in pixels (default `(800, 800)`)

# Returns
The `filename` string, so callers can chain: `record_simulation(...) |> println`.
"""
function record_simulation(state::SimulationState, filename::AbstractString;
    duration   = 5.0,
    framerate  = 30,
    substeps   = nothing,
    resolution = (800, 800),
)
    boundary = state.boundary

    if substeps === nothing
        substeps = max(1, round(Int, 1.0 / (framerate * state.dt)))
    end
    nframes = round(Int, duration * framerate)

    # Observables drive Makie's reactive rendering
    positions = Observable(Point2f[Point2f(b.pos...) for b in state.balls])
    radii     = Observable(Float32[b.radius           for b in state.balls])
    colors    = Observable([b.color                   for b in state.balls])

    fig = Figure(; size=resolution)
    ax  = Axis(fig[1, 1];
        aspect  = DataAspect(),
        limits  = (boundary.xmin, boundary.xmax, boundary.ymin, boundary.ymax),
        title   = "Elastic Balls 2D",
        xlabel  = "x",
        ylabel  = "y",
    )

    scatter!(ax, positions;
        color       = colors,
        markersize  = radii,
        markerspace = :data,
        marker      = Circle,
        strokewidth = 1,
        strokecolor = :black,
    )

    record(fig, filename; framerate=framerate) do io
        for _ in 1:nframes
            for _ in 1:substeps
                step!(state)
            end
            positions[] = Point2f[Point2f(b.pos...) for b in state.balls]
            radii[]     = Float32[b.radius           for b in state.balls]
            colors[]    = [b.color                   for b in state.balls]
            recordframe!(io)
        end
    end

    return filename
end
