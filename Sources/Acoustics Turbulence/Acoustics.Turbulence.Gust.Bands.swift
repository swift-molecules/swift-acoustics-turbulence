internal import Numeric

extension Acoustics.Turbulence.Gust {
    /// The cosines of one realization: an amplitude, an angular frequency and a phase for each band.
    struct Bands: Sendable {
        var amplitudes: [Double]
        var angular: [Double]
        var phases: [Double]
    }
}

extension Acoustics.Turbulence.Gust.Bands {
    /// The realization's departure from the mean speed at time `t`, in metres per second.
    func value(at t: Double) -> Double {
        amplitudes.indices.reduce(0.0) { sum, k in
            sum + amplitudes[k] * Double.math.cos(angular[k] * t + phases[k])
        }
    }
}
