/// Binary GCD algorithm (Stein's algorithm)
/// Ported from Julia's base/intfuncs.jl
///
/// This is significantly faster than the Euclidean algorithm for machine integers:
/// ~1.7x faster for i64, ~2.1x faster for i128

/// Compute the absolute difference between two unsigned integers
#[inline]
fn absdiff_unsigned(x: u64, y: u64) -> (u64, u64) {
    let d = x.max(y) - x.min(y);
    (d, d)
}

/// Compute the absolute difference between two signed integers
#[inline]
fn absdiff_signed(x: i64, y: i64) -> (u64, i64) {
    let d = x.wrapping_sub(y);
    (d.unsigned_abs(), d)
}

/// Binary GCD algorithm for unsigned 64-bit integers
pub fn gcd_u64(mut a: u64, mut b: u64) -> u64 {
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

        // Compute absolute difference
        let (absd, diff) = absdiff_unsigned(a, b);
        za = diff.trailing_zeros();
        b = a.min(b);
        a = absd;
    }

    // Restore common factors of 2
    b << k
}

/// Binary GCD algorithm for signed 64-bit integers
pub fn gcd_i64(a: i64, b: i64) -> i64 {
    if a == 0 {
        return b.checked_abs().expect("gcd overflow: cannot compute |b|");
    }
    if b == 0 {
        return a.checked_abs().expect("gcd overflow: cannot compute |a|");
    }

    // Handle overflow case for typemin
    if a == i64::MIN {
        if a == b {
            panic!("gcd overflow: gcd({}, {}) overflows", a, b);
        }
        // Swap so that the non-minimum value is processed first
        return gcd_i64(b, a);
    }

    _gcd_i64(a, b)
}

/// Internal binary GCD implementation for signed integers
fn _gcd_i64(ain: i64, bin: i64) -> i64 {
    let zb = bin.trailing_zeros();
    let mut za = ain.trailing_zeros();
    let mut a = ain.unsigned_abs();
    let mut b = (bin >> zb).unsigned_abs();
    let k = za.min(zb);

    while a != 0 {
        a >>= za;

        let (absd, diff) = absdiff_signed(a as i64, b as i64);
        za = (diff as u64).trailing_zeros();
        b = a.min(b);
        a = absd;
    }

    (b << k) as i64
}

/// Binary GCD algorithm for unsigned 128-bit integers
pub fn gcd_u128(mut a: u128, mut b: u128) -> u128 {
    if a == 0 {
        return b;
    }
    if b == 0 {
        return a;
    }

    let mut za = a.trailing_zeros();
    let zb = b.trailing_zeros();
    let k = za.min(zb);

    b >>= zb;

    while a != 0 {
        a >>= za;

        let (absd, diff) = if a >= b { (a - b, a - b) } else { (b - a, b - a) };
        za = diff.trailing_zeros();
        b = a.min(b);
        a = absd;
    }

    b << k
}

/// Binary GCD algorithm for signed 128-bit integers
pub fn gcd_i128(a: i128, b: i128) -> i128 {
    if a == 0 {
        return b.checked_abs().expect("gcd overflow: cannot compute |b|");
    }
    if b == 0 {
        return a.checked_abs().expect("gcd overflow: cannot compute |a|");
    }

    if a == i128::MIN {
        if a == b {
            panic!("gcd overflow: gcd({}, {}) overflows", a, b);
        }
        return gcd_i128(b, a);
    }

    _gcd_i128(a, b)
}

fn _gcd_i128(ain: i128, bin: i128) -> i128 {
    let zb = bin.trailing_zeros();
    let mut za = ain.trailing_zeros();
    let mut a = ain.unsigned_abs();
    let mut b = (bin >> zb).unsigned_abs();
    let k = za.min(zb);

    while a != 0 {
        a >>= za;

        // Compute absolute difference
        let (absd, diff) = if a >= b {
            (a - b, a.wrapping_sub(b))
        } else {
            (b - a, a.wrapping_sub(b))
        };
        za = diff.trailing_zeros();
        b = a.min(b);
        a = absd;
    }

    (b << k) as i128
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

    #[test]
    #[should_panic(expected = "gcd overflow")]
    fn test_gcd_i64_overflow() {
        gcd_i64(i64::MIN, i64::MIN);
    }

    #[test]
    fn test_gcd_i64_min_with_other() {
        // gcd(MIN, 2) should work since we swap
        assert_eq!(gcd_i64(i64::MIN, 2), 2);
    }
}


use std::time::Instant;

// Function to approximate pi using probability that two numbers are coprime
fn calc_pi(n: i64) -> f64 {
    let mut cnt = 0;    // Counter for coprime pairs
    // Loop through all pairs (a, b) where 1 <= a, b <= N
    for a in 1..=n {
        for b in 1..=n {
            // Check if a and b are coprime
            if gcd_i64(a, b) == 1 {
                cnt += 1;  // Increment counter if coprime
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
    let n = 10000;              // Number limit for coprimality checking
    let start = Instant::now();
    let pi = calc_pi(n);        // Approximate pi
    let duration = start.elapsed();
    
    println!("calcPi: {:?}", duration);
    println!("N: {}", n);       // Output N
    println!("pi: {}", pi);     // Output approximation of pi
}
