extension Acoustics.Turbulence {
    /// A circular cylinder across the wind, such as a wire, a twig or a mast, and the aeolian tone it sheds.
    ///
    /// The vortices it sheds pull it sideways at the shedding frequency. That fluctuating lift is a compact dipole,
    /// and its sound is Curle's (1955): p = cos θ / (4π c r) × dF/dt. The lift on a length of the cylinder is
    /// ½ ρ U² d × length × `lift`, and lengths further apart than `correlation` shed independently, so their sounds
    /// add in power (Phillips 1956).
    public struct Cylinder: Hashable, Sendable {
        public var diameter: Length<Space.Physical, Double>
        /// How long the cylinder is, across the wind.
        public var span: Length<Space.Physical, Double>
        /// The root-mean-square fluctuating lift coefficient, C′L. It depends on the Reynolds number; Norberg (2003,
        /// J. Fluids Struct. 17, 57–96) reviews the measurements.
        public var lift: Double
        /// The spanwise correlation length of the shedding: how far along the cylinder the vortices stay in step.
        public var correlation: Length<Space.Physical, Double>

        @inlinable
        public init(
            diameter: Length<Space.Physical, Double>,
            span: Length<Space.Physical, Double>,
            lift: Double,
            correlation: Length<Space.Physical, Double>
        ) {
            self.diameter = diameter
            self.span = span
            self.lift = lift
            self.correlation = correlation
        }
    }
}

extension Acoustics.Turbulence.Cylinder {
    /// The frequency of the aeolian tone in wind of this speed, St U / d, or `nil` where no vortices are shed.
    @inlinable
    public func shedding(speed: Velocity.Value<Double>, air: Acoustics.Air) -> Frequency.Value<Double>? {
        let reynolds = Acoustics.Turbulence.reynolds(speed: speed, size: diameter, air: air)
        guard let strouhal = Acoustics.Turbulence.strouhal(reynolds: reynolds) else { return nil }
        return Frequency.hertz(strouhal * speed.underlying / diameter.underlying)
    }

    /// The root-mean-square pressure of the aeolian tone at `distance`, where `alignment` is the cosine of the angle
    /// between the lift (across the wind and the cylinder) and the way to the listener.
    ///
    /// With ω = 2π St U / d, Curle's dipole gives p = ω ½ ρ U² d C′L cos θ √(L min(L, Λ)) / (4π c r), which is
    /// St ρ U³ C′L cos θ √(L min(L, Λ)) / (4 c r): Phillips's (1956) U⁶ law for the intensity.
    @inlinable
    public func pressure(
        speed: Velocity.Value<Double>,
        air: Acoustics.Air,
        distance: Length<Space.Physical, Double>,
        alignment: Double
    ) -> Pressure.Value<Double> {
        guard let frequency = shedding(speed: speed, air: air) else { return .zero }
        let u = speed.underlying
        let omega = frequency.angular.underlying
        let length = span.underlying
        let coherent = Swift.min(length, correlation.underlying)
        let force = 0.5 * air.density.underlying * u * u * diameter.underlying * lift
        let p = omega * force * alignment * (length * coherent).squareRoot()
            / (4 * Double.pi * air.speed.underlying * distance.underlying)
        return Pressure.pascals(Swift.abs(p))
    }
}
