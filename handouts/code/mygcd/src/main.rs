/// Binary GCD algorithm (Stein's algorithm)
/// Ported from Julia's base/intfuncs.jl
///
/// This is significantly faster than the Euclidean algorithm for machine integers:
/// ~1.7x faster for i64, ~2.1x faster for i128

use std::time::Instant;

/// Macro to generate optimized GCD implementations for unsigned types
macro_rules! impl_gcd_unsigned {
    ($name:ident, $t:ty) => {
        #[inline]
        pub fn $name(mut a: $t, mut b: $t) -> $t {
            if a == 0 {
                return b;
            }
            if b == 0 {
                return a;
            }

            // Factor out common powers of 2
            let mut za = a.trailing_zeros();
            let zb = b.trailing_zeros();
            let k = za.min(zb);

            // Remove factors of 2 from b
            b >>= zb;

            while a != 0 {
                // Remove factors of 2 from a
                a >>= za;

                // Compute absolute difference (original pattern)
                let d = a.max(b) - a.min(b);
                za = d.trailing_zeros();
                b = a.min(b);
                a = d;
            }

            // Restore common factors of 2
            b << k
        }
    };
}

/// Macro to generate optimized GCD implementations for signed types
macro_rules! impl_gcd_signed {
    ($name:ident, $t:ty, $ut:ty) => {
        #[inline]
        pub fn $name(ain: $t, bin: $t) -> $t {
            if ain == 0 {
                return bin.abs();
            }
            if bin == 0 {
                return ain.abs();
            }

            // Match original Julia port pattern exactly
            let zb = bin.trailing_zeros();
            let mut za = ain.trailing_zeros();
            let mut a = ain.unsigned_abs();
            let mut b = (bin >> zb).unsigned_abs();
            let k = za.min(zb);

            while a != 0 {
                a >>= za;

                // Use wrapping_sub pattern from original
                let diff = (a as $t).wrapping_sub(b as $t);
                let absd = diff.unsigned_abs();
                za = (diff as $ut).trailing_zeros();
                b = a.min(b);
                a = absd;
            }

            (b << k) as $t
        }
    };
}

// Generate specialized implementations
impl_gcd_unsigned!(gcd_u8, u8);
impl_gcd_unsigned!(gcd_u16, u16);
impl_gcd_unsigned!(gcd_u32, u32);
impl_gcd_unsigned!(gcd_u64, u64);
impl_gcd_unsigned!(gcd_u128, u128);
impl_gcd_unsigned!(gcd_usize, usize);

impl_gcd_signed!(gcd_i8, i8, u8);
impl_gcd_signed!(gcd_i16, i16, u16);
impl_gcd_signed!(gcd_i32, i32, u32);
impl_gcd_signed!(gcd_i64, i64, u64);
impl_gcd_signed!(gcd_i128, i128, u128);
impl_gcd_signed!(gcd_isize, isize, usize);

/// Generic GCD using Euclidean algorithm (fallback for any type)
pub fn gcd_euclidean<T>(mut a: T, mut b: T) -> T
where
    T: Copy + PartialEq + Default + std::ops::Rem<Output = T>,
{
    let zero = T::default();
    while b != zero {
        let t = b;
        b = a % b;
        a = t;
    }
    a
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gcd_u64() {
        assert_eq!(gcd_u64(0, 5), 5);
        assert_eq!(gcd_u64(5, 0), 5);
        assert_eq!(gcd_u64(12, 8), 4);
        assert_eq!(gcd_u64(48, 18), 6);
        assert_eq!(gcd_u64(17, 13), 1);
        assert_eq!(gcd_u64(100, 25), 25);
        assert_eq!(gcd_u64(1071, 462), 21);
    }

    #[test]
    fn test_gcd_u32() {
        assert_eq!(gcd_u32(0, 5), 5);
        assert_eq!(gcd_u32(12, 8), 4);
        assert_eq!(gcd_u32(48, 18), 6);
    }

    #[test]
    fn test_gcd_i64() {
        assert_eq!(gcd_i64(0, 5), 5);
        assert_eq!(gcd_i64(5, 0), 5);
        assert_eq!(gcd_i64(12, 8), 4);
        assert_eq!(gcd_i64(-12, 8), 4);
        assert_eq!(gcd_i64(12, -8), 4);
        assert_eq!(gcd_i64(-12, -8), 4);
        assert_eq!(gcd_i64(48, 18), 6);
        assert_eq!(gcd_i64(-48, -18), 6);
    }

    #[test]
    fn test_gcd_i32() {
        assert_eq!(gcd_i32(0, 5), 5);
        assert_eq!(gcd_i32(-12, 8), 4);
        assert_eq!(gcd_i32(12, -8), 4);
    }

    #[test]
    fn test_gcd_u128() {
        assert_eq!(gcd_u128(0, 5), 5);
        assert_eq!(gcd_u128(5, 0), 5);
        assert_eq!(gcd_u128(12, 8), 4);
        assert_eq!(gcd_u128(1071, 462), 21);
    }

    #[test]
    fn test_gcd_i128() {
        assert_eq!(gcd_i128(0, 5), 5);
        assert_eq!(gcd_i128(-12, 8), 4);
        assert_eq!(gcd_i128(12, -8), 4);
        assert_eq!(gcd_i128(-12, -8), 4);
    }
}

// Function to approximate pi using probability that two numbers are coprime
fn calc_pi(n: i64) -> f64 {
    let mut cnt = 0i64; // Counter for coprime pairs
    // Loop through all pairs (a, b) where 1 <= a, b <= N
    for a in 1..=n {
        for b in 1..=n {
            // Check if a and b are coprime
            if gcd_i64(a, b) == 1 {
                cnt += 1; // Increment counter if coprime
            }
        }
    }
    // Probability that two numbers are coprime
    let prob = cnt as f64 / (n * n) as f64;
    // Approximate pi using the formula: pi ≈ sqrt(6 / prob)
    (6.0 / prob).sqrt()
}

// Main function to run the pi approximation
fn main() {
    let n: i64 = 10000;

    // Warmup
    let _ = calc_pi(100);

    // Benchmark
    println!("Benchmark:");
    for i in 1..=3 {
        let start = Instant::now();
        let pi = calc_pi(n);
        let duration = start.elapsed();
        println!("Run {}: {:?}  pi={}", i, duration, pi);
    }
}
