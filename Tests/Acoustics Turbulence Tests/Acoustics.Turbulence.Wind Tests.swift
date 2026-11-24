import Acoustics_Turbulence
import Testing

@Suite struct `Acoustics.Turbulence.Wind Tests` {
    let wire = Acoustics.Turbulence.Cylinder(
        diameter: Space.Physical.metres(0.004),
        span: Space.Physical.metres(2),
        lift: 0.5,
        correlation: Space.Physical.metres(0.02)
    )
    let rate = 48_000.0

    @Test func `a wire in a steady wind sings at its shedding frequency and level`() {
        let speed = Velocity.amount(10.0)
        let wind = Acoustics.Turbulence.Wind(
            gust: .steady(speed),
            bodies: [.init(cylinder: wire, distance: Space.Physical.metres(3))]
        )
        let samples = wind.pressures(count: 48_000, interval: Time.Duration.amount(1 / rate)).map(\.underlying)
        let expected = wire.shedding(speed: speed, air: .room)!.underlying
        var crossings: [Double] = []
        for i in 1..<samples.count where samples[i - 1] < 0 && samples[i] >= 0 {
            crossings.append(Double(i - 1) + samples[i - 1] / (samples[i - 1] - samples[i]))
        }
        let measured = Double(crossings.count - 1) / ((crossings.last! - crossings.first!) / rate)
        #expect(abs(measured / expected - 1) < 1e-3)
        let rms = (samples.reduce(0) { $0 + $1 * $1 } / Double(samples.count)).squareRoot()
        let level = wire.pressure(speed: speed, air: .room, distance: Space.Physical.metres(3), alignment: 1)
        #expect(abs(rms / level.underlying - 1) < 1e-2)
    }

    @Test func `a tone above half the sampling rate is silent`() {
        let pin = Acoustics.Turbulence.Cylinder(
            diameter: Space.Physical.metres(0.0001), span: Space.Physical.metres(0.1), lift: 0.5,
            correlation: Space.Physical.metres(0.0005)
        )
        let wind = Acoustics.Turbulence.Wind(
            gust: .steady(Velocity.amount(20)),
            bodies: [.init(cylinder: pin, distance: Space.Physical.metres(1))]
        )
        let samples = wind.pressures(count: 480, interval: Time.Duration.amount(1 / rate))
        #expect(samples.allSatisfy { $0 == .zero })
    }

    @Test func `a thicket is the same for the same seed and spreads its twigs as asked`() {
        let twigs = Acoustics.Turbulence.Wind.Body.thicket(
            count: 40,
            thinnest: Space.Physical.metres(0.002),
            thickest: Space.Physical.metres(0.02),
            span: Space.Physical.metres(0.3),
            lift: 0.5,
            correlation: 5,
            nearest: Space.Physical.metres(2),
            farthest: Space.Physical.metres(10),
            seed: 1
        )
        #expect(twigs.allSatisfy { $0.cylinder.diameter.underlying >= 0.002 && $0.cylinder.diameter.underlying <= 0.02 })
        #expect(twigs.allSatisfy { $0.distance.underlying >= 2 && $0.distance.underlying <= 10 })
        #expect(twigs.allSatisfy { abs($0.alignment) <= 1 })
        let gust = Acoustics.Turbulence.Gust(
            mean: Velocity.amount(8), deviation: Velocity.amount(2), scale: Space.Physical.metres(40)
        )
        let a = Acoustics.Turbulence.Wind(gust: gust, bodies: twigs, seed: 5)
        let interval = Time.Duration.amount(1 / rate)
        #expect(a.pressures(count: 2_000, interval: interval) == a.pressures(count: 2_000, interval: interval))
    }
}
