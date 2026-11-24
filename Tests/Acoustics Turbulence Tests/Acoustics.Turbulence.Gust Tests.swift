import Acoustics_Turbulence
import Numeric
import Testing

@Suite struct `Acoustics.Turbulence.Gust Tests` {
    let gust = Acoustics.Turbulence.Gust(
        mean: Velocity.amount(8),
        deviation: Velocity.amount(1.5),
        scale: Space.Physical.metres(40)
    )

    @Test func `von Kármán's spectrum integrates to the variance`() {
        // ∫ S df over 10⁻⁶ to 10⁴ Hz, by the trapezoid rule in log frequency.
        let steps = 200_000
        let low = Double.math.log(1e-6)
        let high = Double.math.log(1e4)
        let h = (high - low) / Double(steps)
        var sum = 0.0
        for k in 0...steps {
            let f = Double.math.exp(low + h * Double(k))
            let weight = (k == 0 || k == steps) ? 0.5 : 1
            sum += weight * gust.spectrum(at: Frequency.hertz(f)) * f * h
        }
        #expect(abs(sum / (1.5 * 1.5) - 1) < 1e-3)
    }

    @Test func `at high frequency it falls as f to the minus five thirds`() {
        let a = gust.spectrum(at: Frequency.hertz(100))
        let b = gust.spectrum(at: Frequency.hertz(1000))
        let slope = Double.math.log(b / a) / Double.math.log(10)
        #expect(abs(slope + 5.0 / 3.0) < 1e-3)
    }

    @Test func `a realization keeps the mean and the variance its bands carry`() {
        let interval = Time.Duration.amount(0.15)
        let count = 24_000
        let speeds = gust.speeds(count: count, interval: interval, highest: Frequency.hertz(3), seed: 3)
        let mean = speeds.reduce(0.0) { $0 + $1.underlying } / Double(count)
        let variance = speeds.reduce(0.0) { $0 + ($1.underlying - mean) * ($1.underlying - mean) } / Double(count)
        // Bands from 1 / 3600 s to 3 Hz hold almost all of σ² = 2.25; the lowest bands are few cycles long, so
        // one realization scatters.
        #expect(abs(mean - 8) < 0.5)
        #expect(abs(variance / 2.25 - 1) < 0.3)
    }

    @Test func `the same seed gives the same gusts`() {
        let interval = Time.Duration.amount(0.01)
        #expect(gust.speeds(count: 100, interval: interval, seed: 9) == gust.speeds(count: 100, interval: interval, seed: 9))
        #expect(gust.speeds(count: 100, interval: interval, seed: 9) != gust.speeds(count: 100, interval: interval, seed: 8))
    }
}
