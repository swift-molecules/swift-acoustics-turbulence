internal import Numeric
internal import Threefry

extension Acoustics.Turbulence {
    /// The wind as it gusts: a mean speed and the turbulence along it, with von Kármán's (1948) spectrum in the form
    /// wind engineering uses, S(f) = 4 σ² (L / U) / (1 + 70.8 (f L / U)²)^(5/6) (IEC 61400-1, Annex C). It integrates
    /// to σ², and falls as f^(−5/3) at high frequency, Kolmogorov's (1941) inertial range.
    public struct Gust: Hashable, Sendable {
        /// The mean wind speed, U.
        public var mean: Velocity.Value<Double>
        /// The standard deviation of the speed about its mean, σ.
        public var deviation: Velocity.Value<Double>
        /// The integral length scale of the turbulence along the wind, L.
        public var scale: Length<Space.Physical, Double>

        @inlinable
        public init(
            mean: Velocity.Value<Double>,
            deviation: Velocity.Value<Double>,
            scale: Length<Space.Physical, Double>
        ) {
            self.mean = mean
            self.deviation = deviation
            self.scale = scale
        }
    }
}

extension Acoustics.Turbulence.Gust {
    /// A steady wind, with no turbulence.
    @inlinable
    public static func steady(_ speed: Velocity.Value<Double>) -> Self {
        Self(mean: speed, deviation: .zero, scale: Space.Physical.metres(1))
    }

    /// The one-sided power spectral density of the speed at `frequency`, in (m/s)² per hertz.
    public func spectrum(at frequency: Frequency.Value<Double>) -> Double {
        let time = scale.underlying / mean.underlying
        let x = frequency.underlying * time
        let sigma = deviation.underlying
        return 4 * sigma * sigma * time / Double.math.pow(1 + 70.8 * x * x, 5.0 / 6.0)
    }

    /// The speeds of one realization, one for each `interval` over `count` intervals.
    ///
    /// It is the spectral representation of Shinozuka and Deodatis (1991, Appl. Mech. Rev. 44, 191–204):
    /// u(t) = U + Σ √(2 S(fₖ) Δfₖ) cos(2π fₖ t + φₖ), with `components` bands spaced evenly in log frequency from one
    /// over the whole duration to `highest`, and each phase φₖ drawn from the seed.
    public func speeds(
        count: Int,
        interval: Time.Duration.Value<Double>,
        highest: Frequency.Value<Double> = Frequency.hertz(50),
        components: Int = 256,
        seed: UInt64 = 0
    ) -> [Velocity.Value<Double>] {
        let bands = self.bands(
            duration: interval.underlying * Double(Swift.max(count, 1)),
            highest: highest.underlying,
            components: components,
            seed: seed
        )
        return (0..<count).map { index in
            let t = Double(index) * interval.underlying
            return Velocity.amount(mean.underlying + bands.value(at: t))
        }
    }

    struct Bands: Sendable {
        var amplitudes: [Double]
        var angular: [Double]
        var phases: [Double]

        func value(at t: Double) -> Double {
            var sum = 0.0
            for k in amplitudes.indices {
                sum += amplitudes[k] * Double.math.cos(angular[k] * t + phases[k])
            }
            return sum
        }
    }

    func bands(duration: Double, highest: Double, components: Int, seed: UInt64) -> Bands {
        guard deviation.underlying > 0, components > 0, duration > 0 else {
            return Bands(amplitudes: [], angular: [], phases: [])
        }
        let lowest = 1 / duration
        let top = Swift.max(highest, lowest * 2)
        let step = Double.math.log(top / lowest) / Double(components)
        var draws = Threefry.Generator(key: Threefry.Key(seed: seed), stream: 0x6775_7374)
        var bands = Bands(amplitudes: [], angular: [], phases: [])
        for k in 0..<components {
            let low = lowest * Double.math.exp(step * Double(k))
            let high = lowest * Double.math.exp(step * Double(k + 1))
            let centre = (low * high).squareRoot()
            let density = spectrum(at: Frequency.hertz(centre))
            bands.amplitudes.append((2 * density * (high - low)).squareRoot())
            bands.angular.append(2 * Double.pi * centre)
            bands.phases.append(2 * Double.pi * draws.unit(as: Double.self))
        }
        return bands
    }
}
