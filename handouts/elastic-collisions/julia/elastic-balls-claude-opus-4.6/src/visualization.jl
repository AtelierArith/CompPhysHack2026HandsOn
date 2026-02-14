using Makie

"""
    visualize(state::SimulationState; substeps=1, figure_kwargs=NamedTuple())

Open an interactive visualization window for the simulation.
Requires a Makie backend (e.g., GLMakie) to be loaded.

- `substeps`: number of simulation steps per frame (increase for faster simulation)
- `figure_kwargs`: keyword arguments passed to `Figure`
"""
function visualize(state::SimulationState; substeps=1, figure_kwargs=NamedTuple())
    boundary = state.boundary

    # Create observables
    positions = Observable(Point2f[Point2f(b.pos...) for b in state.balls])
    colors = Observable([b.color for b in state.balls])
    sizes = Observable(Float32[2 * b.radius for b in state.balls])

    fig = Figure(; size=(800, 800), figure_kwargs...)
    ax = Axis(fig[1, 1];
        aspect=DataAspect(),
        limits=(boundary.xmin, boundary.xmax, boundary.ymin, boundary.ymax),
        title="Elastic Balls 2D",
    )
    scatter!(ax, positions;
        color=colors,
        markersize=sizes,
        markerspace=:data,
        marker=Circle,
    )

    # Animation control
    running = Observable(true)

    on(events(fig).window_open) do open
        if !open
            running[] = false
        end
    end

    display(fig)

    @async begin
        while running[]
            for _ in 1:substeps
                step!(state)
            end
            positions[] = Point2f[Point2f(b.pos...) for b in state.balls]
            colors[] = [b.color for b in state.balls]
            sizes[] = Float32[2 * b.radius for b in state.balls]
            sleep(1 / 60)
        end
    end

    return fig
end

"""
    record_simulation(state::SimulationState, filename::AbstractString;
                      duration=5.0, framerate=30, substeps=nothing,
                      resolution=(800, 800))

Record the simulation to a GIF or MP4 file.

- `duration`: recording duration in seconds
- `framerate`: frames per second
- `substeps`: simulation steps per frame (auto-computed from dt and framerate if not given)
- `resolution`: figure size in pixels
"""
function record_simulation(state::SimulationState, filename::AbstractString;
    duration=5.0,
    framerate=30,
    substeps=nothing,
    resolution=(800, 800),
)
    boundary = state.boundary

    # Auto-compute substeps: how many simulation steps fit in one frame interval
    if substeps === nothing
        substeps = max(1, round(Int, 1.0 / (framerate * state.dt)))
    end

    nframes = round(Int, duration * framerate)

    # Create observables
    positions = Observable(Point2f[Point2f(b.pos...) for b in state.balls])
    colors = Observable([b.color for b in state.balls])
    sizes = Observable(Float32[2 * b.radius for b in state.balls])

    fig = Figure(; size=resolution)
    ax = Axis(fig[1, 1];
        aspect=DataAspect(),
        limits=(boundary.xmin, boundary.xmax, boundary.ymin, boundary.ymax),
        title="Elastic Balls 2D",
    )
    scatter!(ax, positions;
        color=colors,
        markersize=sizes,
        markerspace=:data,
        marker=Circle,
    )

    record(fig, filename; framerate=framerate) do io
        for _ in 1:nframes
            for _ in 1:substeps
                step!(state)
            end
            positions[] = Point2f[Point2f(b.pos...) for b in state.balls]
            colors[] = [b.color for b in state.balls]
            sizes[] = Float32[2 * b.radius for b in state.balls]
            recordframe!(io)
        end
    end

    return filename
end
