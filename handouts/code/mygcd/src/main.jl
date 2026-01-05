# Binary GCD algorithm (Stein's algorithm)
# Optimized implementation matching Rust performance patterns

"""
    mygcd(a::Int64, b::Int64) -> Int64

Binary GCD algorithm optimized for Int64.
Uses the Rust-style pattern with unsigned arithmetic internally.
"""
@inline function mygcd(ain::Int64, bin::Int64)::Int64
    ain == 0 && return abs(bin)
    bin == 0 && return abs(ain)

    zb::Int = trailing_zeros(bin)
    za::Int = trailing_zeros(ain)
    a::UInt64 = reinterpret(UInt64, abs(ain))
    b::UInt64 = reinterpret(UInt64, abs(bin >> zb))
    k::Int = min(za, zb)

    while a != zero(UInt64)
        a >>= za
        diff::Int64 = reinterpret(Int64, a) - reinterpret(Int64, b)
        absd::UInt64 = reinterpret(UInt64, abs(diff))
        za = trailing_zeros(reinterpret(UInt64, diff))
        b = min(a, b)
        a = absd
    end

    reinterpret(Int64, b << k)
end

"""
    mygcd(a::T, b::T) where T<:Unsigned -> T

Binary GCD algorithm for unsigned integers.
"""
@inline function mygcd(a::T, b::T)::T where T<:Unsigned
    a == 0 && return b
    b == 0 && return a

    shift = trailing_zeros(a | b)
    a >>= trailing_zeros(a)

    while b != 0
        b >>= trailing_zeros(b)
        if a > b
            a, b = b, a
        end
        b -= a
    end

    a << shift
end

"""
    gcd_euclidean(a::T, b::T) where T -> T

Generic GCD using Euclidean algorithm (fallback).
"""
function gcd_euclidean(a::T, b::T)::T where T
    while b != zero(T)
        a, b = b, a % b
    end
    abs(a)
end

# Tests
function run_tests()
    println("Running tests...")

    # Test Int64
    @assert mygcd(Int64(0), Int64(5)) == 5
    @assert mygcd(Int64(5), Int64(0)) == 5
    @assert mygcd(Int64(12), Int64(8)) == 4
    @assert mygcd(Int64(-12), Int64(8)) == 4
    @assert mygcd(Int64(12), Int64(-8)) == 4
    @assert mygcd(Int64(-12), Int64(-8)) == 4
    @assert mygcd(Int64(48), Int64(18)) == 6
    @assert mygcd(Int64(-48), Int64(-18)) == 6
    @assert mygcd(Int64(1071), Int64(462)) == 21

    # Test UInt64
    @assert mygcd(UInt64(0), UInt64(5)) == 5
    @assert mygcd(UInt64(12), UInt64(8)) == 4
    @assert mygcd(UInt64(1071), UInt64(462)) == 21

    println("All tests passed!")
end

"""
    calc_pi(n::Int64) -> Float64

Approximate pi using probability that two numbers are coprime.
The probability that two random integers are coprime is 6/pi^2.
"""
function calc_pi(n::Int64)::Float64
    cnt::Int64 = 0
    @inbounds for a in 1:n
        for b in 1:n
            cnt += ifelse(mygcd(a, b) == 1, 1, 0)
        end
    end
    sqrt(6.0 / (cnt / (n * n)))
end

# Main function
function main()
    run_tests()

    n = Int64(10000)

    # Warmup
    calc_pi(Int64(100))

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
