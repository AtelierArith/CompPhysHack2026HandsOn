module Visualization

using Luxor
using ..Simulation

export create_animation

function create_animation(sim::Sim, frames::Int, filename::String="collision.gif"; dt::Float64=1.0, substeps::Int=1)
    width = Int(round(sim.width))
    height = Int(round(sim.height))

    # Pre-calculate states to ensure thread-safety and deterministic rendering
    all_frames_data = []

    # Use a copy of sim for simulation tracking
    temp_sim = Sim(
        [Ball(copy(b.pos), copy(b.vel), b.mass, b.radius, b.color) for b in sim.balls],
        sim.width,
        sim.height
    )

    println("Pre-calculating $(frames) frames...")
    for f in 1:frames
        # Store current state
        frame_balls = [(pos=copy(b.pos), radius=b.radius, color=b.color) for b in temp_sim.balls]
        push!(all_frames_data, frame_balls)

        # Advance simulation for next frame
        for _ in 1:substeps
            step!(temp_sim, dt / substeps)
        end
    end

    function frame(scene, framenumber)
        background("black")

        # Luxor's animate often defaults the origin to the center of the canvas.
        # We translate to the top-left to match our simulation coordinate system (0 to width, 0 to height).
        origin() # Ensure we are at center
        translate(-width/2, -height/2) # Move to top-left

        # Draw recorded state
        balls_data = all_frames_data[framenumber]
        for b in balls_data
            sethue(b.color)
            circle(Point(b.pos[1], b.pos[2]), b.radius, :fill)
        end
    end

    movie = Movie(width, height, "simulation")
    animate(movie, [Scene(movie, frame, 1:frames)], creategif=true, pathname=filename)
end

end
