internal import Numeric
internal import Threefry

extension Acoustics.Turbulence {
    /// A cylinder in the wind, where it is from the listener.
    public struct Body: Hashable, Sendable {
        public var cylinder: Acoustics.Turbulence.Cylinder
        public var distance: Length<Space.Physical, Double>
        /// The cosine of the angle between the cylinder's lift and the way to the listener.
        public var alignment: Double

        @inlinable
        public init(
            cylinder: Acoustics.Turbulence.Cylinder,
            distance: Length<Space.Physical, Double>,
            alignment: Double = 1
        ) {
            self.cylinder = cylinder
            self.distance = distance
            self.alignment = alignment
        }
    }
}

extension Acoustics.Turbulence.Body {
    /// `count` twigs: diameters spread evenly in log between `thinnest` and `thickest`, distances evenly between
    /// `nearest` and `farthest`, and alignments evenly in [−1, 1], so that their lift points every way. Each is
    /// `span` long, with lift coefficient `lift` and a correlation length of `correlation` diameters.
    public static func thicket(
        count: Int,
        thinnest: Length<Space.Physical, Double>,
        thickest: Length<Space.Physical, Double>,
        span: Length<Space.Physical, Double>,
        lift: Double,
        correlation: Double,
        nearest: Length<Space.Physical, Double>,
        farthest: Length<Space.Physical, Double>,
        seed: UInt64 = 0
    ) -> [Self] {
        let draws = Threefry.Draws(key: Threefry.Key(seed: seed), item: 0, stream: 0x7477_6967)
        let ratio = Double.math.log(thickest.underlying / thinnest.underlying)
        return (0..<count).map { index in
            let k = UInt64(index) * 3
            let diameter = thinnest.underlying * Double.math.exp(ratio * draws.unit(at: k, as: Double.self))
            let near = nearest.underlying
            let distance = near + (farthest.underlying - near) * draws.unit(at: k + 1, as: Double.self)
            let alignment = 2 * draws.unit(at: k + 2, as: Double.self) - 1
            return Self(
                cylinder: Acoustics.Turbulence.Cylinder(
                    diameter: Space.Physical.metres(diameter),
                    span: span,
                    lift: lift,
                    correlation: Space.Physical.metres(correlation * diameter)
                ),
                distance: Space.Physical.metres(distance),
                alignment: alignment
            )
        }
    }
}
