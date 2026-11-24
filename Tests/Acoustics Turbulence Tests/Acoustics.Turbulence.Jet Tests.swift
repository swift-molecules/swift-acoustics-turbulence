import Acoustics_Turbulence
import Numeric
import Testing

@Suite struct `Acoustics.Turbulence.Jet Tests` {
    let jet = Acoustics.Turbulence.Jet(diameter: Space.Physical.metres(0.01))
    let interval = Time.Duration.seconds(1 / 48_000.0)

    /// The power at one spectral line, averaged over segments of `length` samples with a Hann window.
    static func power(_ signal: [Double], at frequency: Double, rate: Double, length: Int = 2_048) -> Double {
        var sum = 0.0
        var segments = 0
        var start = 0
        while start + length <= signal.count {
            var re = 0.0
            var im = 0.0
            var n = 0
            while n < length {
                let window = 0.5 - 0.5 * Double.math.cos(2 * Double.pi * Double(n) / Double(length))
                let phase = 2 * Double.pi * frequency * Double(n) / rate
                re += window * signal[start + n] * Double.math.cos(phase)
                im -= window * signal[start + n] * Double.math.sin(phase)
                n += 1
            }
            sum += re * re + im * im
            segments += 1
            start += length / 2
        }
        return sum / Double(Swift.max(segments, 1))
    }

    @Test func `the power is Lighthill's K ρ U⁸ D² / c⁵`() {
        let air = Acoustics.Air.room
        let w = jet.power(speed: Velocity.amount(20), air: air).underlying
        let expected = 3e-5 * 1.204 * Double.math.pow(20, 8) * 0.0001 / Double.math.pow(343.2, 5)
        #expect(abs(w / expected - 1) < 1e-12)
    }

    @Test func `doubling the speed raises the noise 24 dB, the U⁸ law`() {
        let slow = jet.pressure(speed: Velocity.amount(10), air: .room, distance: Space.Physical.metres(1))
        let fast = jet.pressure(speed: Velocity.amount(20), air: .room, distance: Space.Physical.metres(1))
        #expect(abs(20 * log10(fast / slow) - 80 * log10(2.0)) < 1e-9)
    }

    @Test func `the pressure is the power spread over a sphere`() {
        let air = Acoustics.Air.room
        let w = jet.power(speed: Velocity.amount(15), air: air).underlying
        let p = jet.pressure(speed: Velocity.amount(15), air: air, distance: Space.Physical.metres(2)).underlying
        let intensity = p * p / (1.204 * 343.2)
        #expect(abs(intensity * 4 * Double.pi * 4 / w - 1) < 1e-12)
    }

    @Test func `a steady jet's realization has the root-mean-square pressure of the law`() {
        for speed in [5.0, 15.0, 40.0] {
            let speeds = [Velocity.Value<Double>](repeating: Velocity.amount(speed), count: 96_000)
            let heard = jet.pressures(speeds: speeds, interval: interval).map(\.underlying)
            let rms = (heard.reduce(0) { $0 + $1 * $1 } / Double(heard.count)).squareRoot()
            let law = jet.pressure(speed: Velocity.amount(speed), air: .room, distance: Space.Physical.metres(1))
                .underlying
            #expect(abs(rms / law - 1) < 0.05, "\(speed) m/s: \(rms) against \(law)")
        }
    }

    @Test func `the noise peaks near St U over D and falls away on both sides`() {
        let speeds = [Velocity.Value<Double>](repeating: Velocity.amount(20.0), count: 192_000)
        let noise = jet.turbulence(speeds: speeds, interval: interval)
        let peak = jet.peak(speed: Velocity.amount(20)).underlying
        #expect(abs(peak - 400) < 1e-9)
        let at = Self.power(noise, at: peak, rate: 48_000)
        let below = Self.power(noise, at: peak / 8, rate: 48_000)
        let above = Self.power(noise, at: peak * 8, rate: 48_000)
        // Two equal poles: 4x² / (1 + x²)² is −12.3 dB an eighth of the peak and eight times it.
        #expect(10 * log10(at / below) > 9, "below \(10 * log10(at / below)) dB")
        #expect(10 * log10(at / above) > 9, "above \(10 * log10(at / above)) dB")
        #expect(10 * log10(at / below) < 16)
        #expect(10 * log10(at / above) < 16)
    }

    @Test func `the same seed gives the same jet, another seed another`() {
        let speeds = [Velocity.Value<Double>](repeating: Velocity.amount(10.0), count: 4_800)
        let first = jet.turbulence(speeds: speeds, interval: interval, seed: 3)
        let again = jet.turbulence(speeds: speeds, interval: interval, seed: 3)
        let other = jet.turbulence(speeds: speeds, interval: interval, seed: 4)
        #expect(first == again)
        #expect(first != other)
    }
}

private func log10(_ x: Double) -> Double { Double.math.log(x) / Double.math.log(10) }
