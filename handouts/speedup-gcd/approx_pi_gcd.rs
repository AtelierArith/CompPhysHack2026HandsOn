use std::time::Instant;

// Function to compute the greatest common divisor (GCD) using the Euclidean algorithm
fn mygcd(mut a: i32, mut b: i32) -> i32 {
    // Loop until the remainder is zero
    while b != 0 {
        let tmp = b;    // Store the value of b temporarily
        b = a % b;      // Update b to the remainder of a divided by b
        a = tmp;        // Set a to the previous value of b
    }
    a                   // When b is zero, a is the GCD
}

// Function to approximate pi using probability that two numbers are coprime
fn calc_pi(n: i32) -> f64 {
    let mut cnt = 0;    // Counter for coprime pairs
    // Loop through all pairs (a, b) where 1 <= a, b <= N
    for a in 1..=n {
        for b in 1..=n {
            // Check if a and b are coprime
            if mygcd(a, b) == 1 {
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