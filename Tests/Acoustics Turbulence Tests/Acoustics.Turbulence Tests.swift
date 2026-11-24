import Acoustics_Turbulence
import Testing

@Suite struct `Acoustics.Turbulence Tests` {
    @Test func `the Reynolds number is U d over the air's kinematic viscosity`() {
        let reynolds = Acoustics.Turbulence.reynolds(
            speed: Velocity.amount(10),
            size: Space.Physical.metres(0.004),
            air: .room
        )
        // ν = 1.8e-5 / 1.204 = 1.495 × 10⁻⁵ m²/s, so Re = 10 × 0.004 / ν.
        #expect(abs(reynolds - 10 * 0.004 * 1.204 / 1.8e-5) < 1e-9)
    }

    @Test func `no vortex street forms below Reynolds number 40`() {
        #expect(Acoustics.Turbulence.strouhal(reynolds: 39) == nil)
        #expect(Acoustics.Turbulence.strouhal(reynolds: 40) != nil)
    }

    @Test func `the Strouhal number is Roshko's 1954 fits`() {
        // Stable range: F = 0.212 Re − 4.5; irregular range: F = 0.212 Re − 2.7 (NACA Report 1191).
        #expect(abs(Acoustics.Turbulence.strouhal(reynolds: 100)! - (0.212 * 100 - 4.5) / 100) < 1e-12)
        #expect(abs(Acoustics.Turbulence.strouhal(reynolds: 1000)! - (0.212 * 1000 - 2.7) / 1000) < 1e-12)
        #expect(abs(Acoustics.Turbulence.strouhal(reynolds: 1e5)! - 0.212) < 1e-4)
    }

    @Test(arguments: [50.0, 60, 80, 100, 120, 150])
    func `in the stable range it agrees with Williamson and Brown's 1998 series to 3%`(reynolds: Double) {
        // St = 0.2731 − 1.1129 / √Re + 0.4821 / Re (J. Fluids Struct. 12, 1073–1085), an independent fit; the two
        // agree to 1% from 60 to 120 and part by 2.7% at 50 and 1.9% at 150, the ends of Roshko's fit.
        let series = 0.2731 - 1.1129 / reynolds.squareRoot() + 0.4821 / reynolds
        let roshko = Acoustics.Turbulence.strouhal(reynolds: reynolds)!
        #expect(abs(roshko / series - 1) < 0.03)
    }
}
