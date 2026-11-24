import Acoustics_Turbulence
import Numeric
import Testing

@Suite struct `Acoustics.Turbulence.Flame Tests` {
    let interval = Time.Duration.seconds(1 / 48_000.0)
    let jet = Acoustics.Turbulence.Jet(diameter: Space.Physical.metres(0.004))

    @Test func `a steady flame that does not flicker is silent`() {
        let flame = Acoustics.Turbulence.Flame(jet: jet, flicker: 0)
        let heat = [Power.Value<Double>](repeating: Power.watts(50.0), count: 4_800)
        let speeds = [Velocity.Value<Double>](repeating: Velocity.amount(3.0), count: 4_800)
        let heard = flame.pressures(heat: heat, speeds: speeds, interval: interval).map(\.underlying)
        #expect(heard.dropFirst().allSatisfy { $0 == 0 })
    }

    /// Heat release rising steadily at α watts per second gives a steady pressure (γ − 1) α / (4π c² r).
    @Test func `a flame growing steadily presses steadily, as Hurle and Strahle's monopole`() {
        let flame = Acoustics.Turbulence.Flame(jet: jet, flicker: 0)
        let alpha = 2_000.0
        let heat = (0..<4_800).map { Power.watts(alpha * Double($0) / 48_000) }
        let speeds = [Velocity.Value<Double>](repeating: Velocity.amount(3.0), count: 4_800)
        let heard = flame.pressures(heat: heat, speeds: speeds, interval: interval, distance: Space.Physical.metres(2))
        let expected = 0.4 * alpha / (4 * Double.pi * 343.2 * 343.2 * 2)
        #expect(heard.dropFirst().allSatisfy { abs($0.underlying / expected - 1) < 1e-9 })
    }

    @Test func `a flickering flame roars, louder for more flicker`() {
        let heat = [Power.Value<Double>](repeating: Power.watts(50.0), count: 48_000)
        let speeds = [Velocity.Value<Double>](repeating: Velocity.amount(3.0), count: 48_000)
        func rms(_ flicker: Double) -> Double {
            let heard = Acoustics.Turbulence.Flame(jet: jet, flicker: flicker)
                .pressures(heat: heat, speeds: speeds, interval: interval).dropFirst().map(\.underlying)
            return (heard.reduce(0) { $0 + $1 * $1 } / Double(heard.count)).squareRoot()
        }
        let small = rms(0.05)
        let large = rms(0.1)
        #expect(small > 0)
        #expect(abs(large / small - 2) < 1e-9)
    }
}
