import Acoustics_Turbulence
import Numeric
import Testing

@Suite struct `Acoustics.Turbulence.Cylinder Tests` {
    let wire = Acoustics.Turbulence.Cylinder(
        diameter: Space.Physical.metres(0.004),
        span: Space.Physical.metres(2),
        lift: 0.5,
        correlation: Space.Physical.metres(0.02)
    )

    @Test func `a 4 mm wire in a 10 m/s wind whistles near 527 Hz`() {
        let f = wire.shedding(speed: Velocity.amount(10), air: .room)!
        let reynolds = 10 * 0.004 * 1.204 / 1.8e-5
        let strouhal = 0.212 - 2.7 / reynolds
        #expect(abs(f.underlying - strouhal * 10 / 0.004) < 1e-9)
        #expect(abs(f.underlying - 527.4) < 0.5)
    }

    @Test func `the tone's pressure is Phillips's form of Curle's dipole`() {
        // p_rms = St ρ U³ C′L cos θ √(L Λ) / (4 c r).
        let air = Acoustics.Air.room
        let u = 10.0
        let strouhal = Acoustics.Turbulence.strouhal(reynolds: u * 0.004 * 1.204 / 1.8e-5)!
        let expected = strouhal * 1.204 * u * u * u * 0.5 * 0.6 * (2 * 0.02).squareRoot() / (4 * 343.2 * 3)
        let p = wire.pressure(speed: Velocity.amount(u), air: air, distance: Space.Physical.metres(3), alignment: 0.6)
        #expect(abs(p.underlying / expected - 1) < 1e-12)
    }

    @Test func `doubling the wind raises the tone 18 dB, the U⁶ law, at a steady Strouhal number`() {
        let slow = wire.pressure(speed: Velocity.amount(20), air: .room, distance: Space.Physical.metres(1), alignment: 1)
        let fast = wire.pressure(speed: Velocity.amount(40), air: .room, distance: Space.Physical.metres(1), alignment: 1)
        let stSlow = Acoustics.Turbulence.strouhal(reynolds: 20 * 0.004 * 1.204 / 1.8e-5)!
        let stFast = Acoustics.Turbulence.strouhal(reynolds: 40 * 0.004 * 1.204 / 1.8e-5)!
        let gain = 20 * log10((fast / slow) * stSlow / stFast)
        #expect(abs(gain - 60 * log10(2.0)) < 1e-9)
        #expect(abs(gain - 18.06) < 0.01)
    }

    @Test func `segments further apart than the correlation length add in power`() {
        let short = Acoustics.Turbulence.Cylinder(
            diameter: wire.diameter,
            span: Space.Physical.metres(0.02),
            lift: 0.5,
            correlation: wire.correlation
        )
        let long = Acoustics.Turbulence.Cylinder(
            diameter: wire.diameter,
            span: Space.Physical.metres(0.08),
            lift: 0.5,
            correlation: wire.correlation
        )
        let speed = Velocity.amount(10.0)
        let one = short.pressure(speed: speed, air: .room, distance: Space.Physical.metres(1), alignment: 1)
        let four = long.pressure(speed: speed, air: .room, distance: Space.Physical.metres(1), alignment: 1)
        #expect(abs(four / one - 2) < 1e-12)
    }

    @Test func `the tone has the dimension of pressure`() {
        // St ρ U³ / c × length / length: (M L⁻³)(L³ T⁻³)/(L T⁻¹) = M L⁻¹ T⁻².
        let density = Quantity.Dimension.of(Density.self)
        let speed = Quantity.Dimension.of(Velocity.self)
        let result = density * speed * speed * speed / speed
        #expect(result == Quantity.Dimension.of(Pressure.self))
    }
}

private func log10(_ x: Double) -> Double { Double.math.log(x) / Double.math.log(10) }
