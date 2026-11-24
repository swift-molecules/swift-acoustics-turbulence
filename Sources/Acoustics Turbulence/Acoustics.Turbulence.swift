extension Acoustics {
    /// Sound from moving air: the aeolian tone a body sheds into the wind, the gusts that bend it, and the rush of
    /// many bodies at once.
    public enum Turbulence {}
}

extension Acoustics.Turbulence {
    /// The Reynolds number of air at `speed` past a body of size `size`: U d / ν, with ν the air's kinematic
    /// viscosity (Reynolds 1883).
    @inlinable
    public static func reynolds(
        speed: Velocity.Value<Double>,
        size: Length<Space.Physical, Double>,
        air: Acoustics.Air
    ) -> Double {
        let kinematic: Viscosity.Kinematic.Value<Double> = air.viscosity / air.density
        return speed.underlying * size.underlying / kinematic.underlying
    }

    /// The Strouhal number f d / U of the vortices a circular cylinder sheds at this Reynolds number, or `nil` below
    /// 40, where no vortex street forms.
    ///
    /// Roshko (1954, NACA Report 1191) measured f d² / ν = 0.212 Re − 4.5 in the stable range (40 to 150) and
    /// 0.212 Re − 2.7 in the irregular range (300 to 10 000); divided by Re, St = 0.212 − 4.5 / Re and
    /// St = 0.212 − 2.7 / Re. The transition range, 150 to 300, takes the irregular law, and so does everything above
    /// it, where St stays near 0.21 until the drag crisis near Re = 2 × 10⁵.
    @inlinable
    public static func strouhal(reynolds: Double) -> Double? {
        guard reynolds >= 40 else { return nil }
        return reynolds <= 150 ? 0.212 - 4.5 / reynolds : 0.212 - 2.7 / reynolds
    }
}
