# Binary GCD algorithm (Stein's algorithm)
# Optimized implementation matching Rust performance

using Base: llvmcall

# Unsafe right shift without overflow check (matches Rust behavior)
# Uses @generated to create type-specific LLVM IR
@generated function unsafe_lshr(x::T, n::T) where T<:Unsigned
    bits = sizeof(T) * 8
    llvm_type = "i$bits"
    ir = "%res = lshr $llvm_type %0, %1\nret $llvm_type %res"
    return :(llvmcall($ir, $T, Tuple{$T, $T}, x, n))
end

"""
    mygcd(a::T, b::T) where T<:Signed -> T

Binary GCD algorithm for signed integers.
Uses unsafe shift to match Rust performance.
"""
@inline function mygcd(ain::T, bin::T)::T where T<:Signed
    U = unsigned(T)  # Get unsigned counterpart type

    ain == 0 && return abs(bin)
    bin == 0 && return abs(ain)

    zb = trailing_zeros(bin) % U
    za = trailing_zeros(ain) % U
    a::U = reinterpret(U, abs(ain))
    b::U = reinterpret(U, abs(bin >> zb))
    k = min(zb, za)

    while a != zero(U)
        a = unsafe_lshr(a, za)
        diff = reinterpret(T, a) - reinterpret(T, b)
        absd = reinterpret(U, abs(diff))
        za = trailing_zeros(reinterpret(U, diff)) % U
        b = min(a, b)
        a = absd
    end

    reinterpret(T, b << k)
end

"""
    mygcd(a::T, b::T) where T<:Unsigned -> T

Binary GCD algorithm for unsigned integers.
Uses unsafe shift to match Rust performance.
"""
@inline function mygcd(a::T, b::T)::T where T<:Unsigned
    a == 0 && return b
    b == 0 && return a

    # Factor out common powers of 2
    za = trailing_zeros(a) % T
    zb = trailing_zeros(b) % T
    k = min(za, zb)

    # Remove factors of 2 from b
    b = unsafe_lshr(b, zb)

    while a != zero(T)
        # Remove factors of 2 from a
        a = unsafe_lshr(a, za)

        # Compute absolute difference (a and b are positive, use max-min)
        diff = max(a, b) - min(a, b)
        za = trailing_zeros(diff) % T
        b = min(a, b)
        a = diff
    end

    b << k
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

    # Test Int32
    @assert mygcd(Int32(0), Int32(5)) == 5
    @assert mygcd(Int32(12), Int32(8)) == 4
    @assert mygcd(Int32(-12), Int32(8)) == 4
    @assert mygcd(Int32(1071), Int32(462)) == 21

    # Test Int16
    @assert mygcd(Int16(0), Int16(5)) == 5
    @assert mygcd(Int16(12), Int16(8)) == 4
    @assert mygcd(Int16(-12), Int16(-8)) == 4

    # Test Int8
    @assert mygcd(Int8(0), Int8(5)) == 5
    @assert mygcd(Int8(12), Int8(8)) == 4
    @assert mygcd(Int8(-12), Int8(8)) == 4

    # Test Int128
    @assert mygcd(Int128(0), Int128(5)) == 5
    @assert mygcd(Int128(12), Int128(8)) == 4
    @assert mygcd(Int128(-12), Int128(8)) == 4
    @assert mygcd(Int128(1071), Int128(462)) == 21

    # Test UInt64
    @assert mygcd(UInt64(0), UInt64(5)) == 5
    @assert mygcd(UInt64(12), UInt64(8)) == 4
    @assert mygcd(UInt64(1071), UInt64(462)) == 21

    # Test UInt32
    @assert mygcd(UInt32(0), UInt32(5)) == 5
    @assert mygcd(UInt32(12), UInt32(8)) == 4
    @assert mygcd(UInt32(1071), UInt32(462)) == 21

    # Test UInt16
    @assert mygcd(UInt16(0), UInt16(5)) == 5
    @assert mygcd(UInt16(12), UInt16(8)) == 4

    # Test UInt8
    @assert mygcd(UInt8(0), UInt8(5)) == 5
    @assert mygcd(UInt8(12), UInt8(8)) == 4

    # Test UInt128
    @assert mygcd(UInt128(0), UInt128(5)) == 5
    @assert mygcd(UInt128(12), UInt128(8)) == 4
    @assert mygcd(UInt128(1071), UInt128(462)) == 21

    # Test against Base.gcd
    for a in 1:100, b in 1:100
        @assert mygcd(a, b) == gcd(a, b) "Failed for ($a, $b)"
    end

    println("All tests passed!")
end

"""
    calc_pi(n::Int64) -> Float64

Approximate pi using probability that two numbers are coprime.
The probability that two random integers are coprime is 6/pi^2.
"""
function calc_pi(n)::Float64
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
