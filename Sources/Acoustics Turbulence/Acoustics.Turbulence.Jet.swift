internal import Numeric

extension Acoustics.Turbulence {
    /// A round jet of air leaving an opening into still air, such as a breath through pursed lips or the gas a
    /// burning match head throws off, and the noise of its turbulence.
    ///
    /// The mixing region of a jet is Lighthill's (1952) field of quadrupoles. Their sound power grows as the eighth
    /// power of the speed, W = K ρ U⁸ D² / c⁵, with K a constant of order 10⁻⁵ to 10⁻⁴ (Lighthill 1952, Proc. R.
    /// Soc. A 211, 564–587; 1954, Proc. R. Soc. A 222, 1–32). The spectrum is broadband, peaking where the eddies of
    /// the size of the jet turn over, near a Strouhal number f D / U of 0.2.
    public struct Jet: Hashable, Sendable {
        /// The diameter of the opening, D.
        public var diameter: Length<Space.Physical, Double>
        /// Lighthill's constant K.
        public var constant: Double
        /// The Strouhal number f D / U at which the noise peaks.
        public var strouhal: Double

        /// A jet from an opening of `diameter`, with K = 3 × 10⁻⁵ and a peak at St = 0.2.
        ///
        /// Both values are chosen: K at the low end of the range Lighthill's law is quoted with for cold subsonic
        /// jets, and St = 0.2 near the peak of a jet's noise heard to the side.
        @inlinable
        public init(diameter: Length<Space.Physical, Double>, constant: Double = 3e-5, strouhal: Double = 0.2) {
            self.diameter = diameter
            self.constant = constant
            self.strouhal = strouhal
        }
    }
}

extension Acoustics.Turbulence.Jet {
    /// The frequency at which the noise of a jet of this `speed` peaks, St U / D.
    @inlinable
    public func peak(speed: Velocity.Value<Double>) -> Frequency.Value<Double> {
        Frequency.hertz(strouhal * Swift.max(speed.underlying, 0) / diameter.underlying)
    }

    /// The sound power of a jet of this `speed`, Lighthill's W = K ρ U⁸ D² / c⁵.
    @inlinable
    public func power(speed: Velocity.Value<Double>, air: Acoustics.Air) -> Power.Value<Double> {
        let u = Swift.max(speed.underlying, 0)
        let u2 = u * u
        let u4 = u2 * u2
        let c = air.speed.underlying
        let c2 = c * c
        let d = diameter.underlying
        return Power.watts(constant * air.density.underlying * u4 * u4 * d * d / (c2 * c2 * c))
    }

    /// The root-mean-square sound pressure at `distance`, the jet's power spread evenly over a sphere:
    /// p = √(ρ c W / (4π r²)). The jet's directivity is left out.
    @inlinable
    public func pressure(
        speed: Velocity.Value<Double>,
        air: Acoustics.Air,
        distance: Length<Space.Physical, Double>
    ) -> Pressure.Value<Double> {
        let w = power(speed: speed, air: air).underlying
        let r = distance.underlying
        let intensity = w / (4 * Double.pi * r * r)
        return Pressure.pascals((air.density.underlying * air.speed.underlying * intensity).squareRoot())
    }

    /// The sound pressure at `distance` from a jet whose speed is `speeds`, one for each `interval`.
    ///
    /// Each sample is the root-mean-square pressure of `pressure(speed:air:distance:)` at that speed times one
    /// realization of `turbulence(speeds:interval:seed:)`.
    public func pressures(
        speeds: [Velocity.Value<Double>],
        interval: Time.Duration.Value<Double>,
        air: Acoustics.Air = .room,
        distance: Length<Space.Physical, Double> = Space.Physical.metres(1),
        seed: UInt64 = 0
    ) -> [Pressure.Value<Double>] {
        let noise = turbulence(speeds: speeds, interval: interval, seed: seed)
        return speeds.indices.map { index in
            Pressure.pascals(pressure(speed: speeds[index], air: air, distance: distance).underlying * noise[index])
        }
    }

    /// One realization of the jet's turbulence as it is heard, with a root-mean-square value of 1 at every
    /// speed, one value for each `interval`.
    ///
    /// White noise drawn from the seed passes through a band-pass of two equal poles at the peak frequency of
    /// each sample's speed, Q = ½, so the spectrum rises as f² below the peak and falls as f⁻² above it (shape
    /// chosen). The filter is Zavalishin's (2012, *The Art of VA Filter Design*, ch. 4) state-variable form, which
    /// stays stable as its frequency moves. Its output is divided by its exact root-mean-square value for white
    /// noise, √(2a / (1 + a)²), a = tan(π f / fₛ).
    public func turbulence(
        speeds: [Velocity.Value<Double>],
        interval: Time.Duration.Value<Double>,
        seed: UInt64 = 0
    ) -> [Double] {
        var shaper = Acoustics.Turbulence.Jet.Shaper(seed: seed)
        let dt = interval.underlying
        return speeds.map { speed in
            shaper.next(peak: peak(speed: speed).underlying * dt)
        }
    }
}
