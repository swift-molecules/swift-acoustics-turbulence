internal import Numeric

extension Acoustics.Turbulence {
    /// A small open flame burning in a jet of its own gas, such as a match head as it flares, and the sound of its
    /// burning.
    ///
    /// Burning gas expands. A flame whose rate of heat release Q̇ changes is a monopole of volume flow
    /// (γ − 1) Q̇ / (ρ c²), and its sound at r is p = (γ − 1) / (4π c² r) × dQ̇/dt (Hurle, Price, Sugden and Thomas
    /// 1968, Proc. R. Soc. A 303, 409–427; Strahle 1971, J. Fluid Mech. 49, 399–414). The heat release rises and
    /// falls as a whole, which is heard as a thump, and flickers with the turbulence of the jet it burns in, which
    /// is heard as a roar.
    public struct Flame: Hashable, Sendable {
        /// The jet the flame burns in, which sets the frequencies of its flicker.
        public var jet: Jet
        /// The root-mean-square flicker of the heat release, as a share of its mean.
        public var flicker: Double
        /// The ratio of the gas's heat capacities, γ.
        public var ratio: Double

        /// A flame in `jet` whose heat release flickers by `flicker` of its mean. γ = 1.4, air's (the burnt gas
        /// is mostly the air's nitrogen).
        @inlinable
        public init(jet: Jet, flicker: Double, ratio: Double = 1.4) {
            self.jet = jet
            self.flicker = flicker
            self.ratio = ratio
        }
    }
}

extension Acoustics.Turbulence.Flame {
    /// The sound pressure at `distance` from a flame whose mean heat release is `heat` and whose gas leaves at
    /// `speeds`, one of each for each `interval`.
    ///
    /// The heat release is Q̄ (1 + `flicker` n), with n the jet's turbulence (`Jet.turbulence`) passed once more
    /// through a one-pole low-pass at the same peak and doubled, which keeps its root-mean-square value near 1
    /// and makes the heat release fall as f⁻⁴ above its peak, so the sound falls as f⁻² (chosen). dQ̇/dt is the
    /// difference of successive samples over `interval`.
    public func pressures(
        heat: [Power.Value<Double>],
        speeds: [Velocity.Value<Double>],
        interval: Time.Duration.Value<Double>,
        air: Acoustics.Air = .room,
        distance: Length<Space.Physical, Double> = Space.Physical.metres(1),
        seed: UInt64 = 0
    ) -> [Pressure.Value<Double>] {
        let count = Swift.min(heat.count, speeds.count)
        let dt = interval.underlying
        let noise = jet.turbulence(speeds: Array(speeds.prefix(count)), interval: interval, seed: seed)
        let c = air.speed.underlying
        let scale = (ratio - 1) / (4 * Double.pi * c * c * distance.underlying)
        var state = 0.0
        var previous = 0.0
        var out = [Pressure.Value<Double>]()
        out.reserveCapacity(count)
        var index = 0
        while index < count {
            let share = Swift.min(Swift.max(jet.peak(speed: speeds[index]).underlying * dt, 1e-6), 0.45)
            let g = Double.math.tan(Double.pi * share)
            let v = (noise[index] - state) * g / (1 + g)
            let low = v + state
            state = low + v
            let released = heat[index].underlying * (1 + flicker * 2 * low)
            out.append(Pressure.pascals(scale * (released - previous) / dt))
            previous = released
            index += 1
        }
        return out
    }
}
