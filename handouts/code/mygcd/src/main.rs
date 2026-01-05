/// Binary GCD algorithm (Stein's algorithm)
/// Ported from Julia's base/intfuncs.jl
///
/// This is significantly faster than the Euclidean algorithm for machine integers:
/// ~1.7x faster for i64, ~2.1x faster for i128

use num_traits::{PrimInt, Signed, Unsigned};
use std::time::Instant;

/// Binary GCD algorithm for unsigned integers using generics
pub fn gcd<T>(mut a: T, mut b: T) -> T
where
    T: PrimInt + Unsigned,
{
    if a.is_zero() {
        return b;
    }
    if b.is_zero() {
        return a;
    }

    // Factor out common powers of 2
    let za = a.trailing_zeros();
    let zb = b.trailing_zeros();
    let k = za.min(zb);

    // Remove all factors of 2 from a and b
    a = a >> za as usize;
    b = b >> zb as usize;

    loop {
        // Ensure a <= b
        if a > b {
            std::mem::swap(&mut a, &mut b);
        }

        // b = b - a (both are odd, so result is even or zero)
        b = b - a;

        if b.is_zero() {
            break;
        }

        // Remove factors of 2 from b
        b = b >> b.trailing_zeros() as usize;
    }

    // Restore common factors of 2
    a << k as usize
}

/// Binary GCD algorithm for signed integers using generics
pub fn gcd_signed<T>(a: T, b: T) -> T
where
    T: PrimInt + Signed,
{
    // Handle zero cases with absolute value
    if a.is_zero() {
        return if b < T::zero() { T::zero() - b } else { b };
    }
    if b.is_zero() {
        return if a < T::zero() { T::zero() - a } else { a };
    }

    // Convert to absolute values
    let mut abs_a = if a < T::zero() { T::zero() - a } else { a };
    let mut abs_b = if b < T::zero() { T::zero() - b } else { b };

    // Factor out common powers of 2
    let za = abs_a.trailing_zeros();
    let zb = abs_b.trailing_zeros();
    let k = za.min(zb);

    // Remove all factors of 2
    abs_a = abs_a >> za as usize;
    abs_b = abs_b >> zb as usize;

    loop {
        // Ensure abs_a <= abs_b
        if abs_a > abs_b {
            std::mem::swap(&mut abs_a, &mut abs_b);
        }

        // abs_b = abs_b - abs_a
        abs_b = abs_b - abs_a;

        if abs_b.is_zero() {
            break;
        }

        // Remove factors of 2 from abs_b
        abs_b = abs_b >> abs_b.trailing_zeros() as usize;
    }

    // Restore common factors of 2
    abs_a << k as usize
}

/// Generic GCD using Euclidean algorithm (fallback)
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
        assert_eq!(gcd(0u32, 5), 5);
        assert_eq!(gcd(12u32, 8), 4);
        assert_eq!(gcd(48u32, 18), 6);
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
        assert_eq!(gcd_signed(0i32, 5), 5);
        assert_eq!(gcd_signed(-12i32, 8), 4);
        assert_eq!(gcd_signed(12i32, -8), 4);
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
    let mut cnt = 0; // Counter for coprime pairs
    // Loop through all pairs (a, b) where 1 <= a, b <= N
    for a in 1..=n {
        for b in 1..=n {
            // Check if a and b are coprime
            if gcd_signed(a, b) == 1 {
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
    let n = 10000; // Number limit for coprimality checking
    let start = Instant::now();
    let pi = calc_pi(n); // Approximate pi
    let duration = start.elapsed();

    println!("calcPi: {:?}", duration);
    println!("N: {}", n); // Output N
    println!("pi: {}", pi); // Output approximation of pi
}
