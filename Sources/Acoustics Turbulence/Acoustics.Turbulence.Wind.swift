internal import Numeric
internal import Threefry

extension Acoustics.Turbulence {
    /// Wind heard at one place: gusts in the air, and the bodies they blow past, each shedding its aeolian tone.
    ///
    /// One wire whistles; a thicket of twigs of many diameters, each shedding at its own frequency and each bent by
    /// the same gusts, sums to a broadband rush.
    public struct Wind: Sendable {
        public var air: Acoustics.Air
        public var gust: Gust
        public var bodies: [Body]
        /// Draws the gusts' phases and each body's starting phase.
        public var seed: UInt64

        @inlinable
        public init(air: Acoustics.Air = .room, gust: Gust, bodies: [Body], seed: UInt64 = 0) {
            self.air = air
            self.gust = gust
            self.bodies = bodies
            self.seed = seed
        }
    }
}

extension Acoustics.Turbulence.Wind {
    /// The sound pressure at the listener, one value for each `interval` over `count` intervals.
    ///
    /// Every 32 samples the gust speed is read at the middle of the block; each body's tone takes that speed's
    /// shedding frequency, and its amplitude, √2 times the root-mean-square pressure of `Cylinder.pressure`, glides
    /// there across the block. A tone at or above half the sampling rate is silent.
    public func pressures(count: Int, interval: Time.Duration.Value<Double>) -> [Pressure.Value<Double>] {
        let dt = interval.underlying
        let block = 32
        let bands = gust.bands(
            duration: dt * Double(Swift.max(count, 1)),
            highest: 50,
            components: 256,
            seed: seed
        )
        var draws = Threefry.Generator(key: Threefry.Key(seed: seed), stream: 0x626F_6479)
        var phasors: [(re: Double, im: Double)] = bodies.indices.map { _ in
            let phase = 2 * Double.pi * draws.unit(as: Double.self)
            return (Double.math.cos(phase), Double.math.sin(phase))
        }
        var amplitudes: [Double?] = Array(repeating: nil, count: bodies.count)
        var out = [Double](repeating: 0, count: count)
        var start = 0
        while start < count {
            let n = Swift.min(block, count - start)
            let t = (Double(start) + Double(n) / 2) * dt
            let speed = Velocity.amount(Swift.max(0, gust.mean.underlying + bands.value(at: t)))
            for index in bodies.indices {
                let body = bodies[index]
                let hertz = body.cylinder.shedding(speed: speed, air: air)?.underlying ?? 0
                let target: Double
                if hertz > 0, hertz * dt < 0.5 {
                    let rms = body.cylinder.pressure(
                        speed: speed,
                        air: air,
                        distance: body.distance,
                        alignment: body.alignment
                    )
                    target = 2.0.squareRoot() * rms.underlying
                } else {
                    target = 0
                }
                let from = amplitudes[index] ?? target
                let step = (target - from) / Double(n)
                let turn = 2 * Double.pi * hertz * dt
                let c = Double.math.cos(turn)
                let s = Double.math.sin(turn)
                var (re, im) = phasors[index]
                for j in 0..<n {
                    out[start + j] += (from + step * Double(j + 1)) * im
                    (re, im) = (re * c - im * s, re * s + im * c)
                }
                let norm = (re * re + im * im).squareRoot()
                phasors[index] = (re / norm, im / norm)
                amplitudes[index] = target
            }
            start += n
        }
        return out.map { Pressure.pascals($0) }
    }
}
