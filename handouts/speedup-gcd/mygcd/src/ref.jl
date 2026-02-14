"""
    calc_pi(n::Int64) -> Float64
Approximate pi using probability that two numbers are coprime.
The probability that two random integers are coprime is 6/pi^2.
"""
function calc_pi(n)::Float64
    cnt::Int64 = 0
    @inbounds for a in 1:n
        for b in 1:n
            cnt += ifelse(gcd(a, b) == 1, 1, 0)
        end
    end
    sqrt(6.0 / (cnt / (n * n)))
end

# Main function
function main()
    n = 10000

    # Warmup
    calc_pi(UInt64(n))

    # Benchmark
    println("\nBenchmark:")
    for i in 1:3
        GC.gc()
        start = time_ns()
        pi_approx = calc_pi(n)
        duration = (time_ns() - start) / 1e9
        println("Run $i: $(duration)s  pi=$pi_approx")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end