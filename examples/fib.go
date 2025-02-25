func fibonacci(n int) int { // Fibonacci in Go
    if n <= 1 {
        return n
    }
    return fibonacci(n-1) + fibonacci(n-2)
}
