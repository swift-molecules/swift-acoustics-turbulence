internal import Numeric
internal import Threefry

extension Acoustics.Turbulence.Jet {
    /// White noise through a band-pass of two equal poles whose frequency may move every sample, scaled to a
    /// root-mean-square value of 1.
    struct Shaper: Sendable {
        var draws: Threefry.Generator
        var first: Double = 0
        var second: Double = 0

        init(seed: UInt64) {
            draws = Threefry.Generator(key: Threefry.Key(seed: seed), stream: 0x6A65_74)
        }
    }
}

extension Acoustics.Turbulence.Jet.Shaper {
    /// The next value, the band-pass centred at `peak` cycles per sample.
    ///
    /// The input is uniform on [−√3, √3], of variance 1. With k = 1 / Q = 2 and g = tan(π f / fₛ), the band-pass
    /// k v₁ has unit gain at its peak; for white noise of variance 1 its variance is 2g / (1 + g)², so it is
    /// divided by the square root of that.
    mutating func next(peak: Double) -> Double {
        let x = (2 * draws.unit(as: Double.self) - 1) * 3.0.squareRoot()
        let share = Swift.min(Swift.max(peak, 1e-6), 0.45)
        let g = Double.math.tan(Double.pi * share)
        let k = 2.0
        let a1 = 1 / (1 + g * (g + k))
        let a2 = g * a1
        let a3 = g * a2
        let v3 = x - second
        let v1 = a1 * first + a2 * v3
        let v2 = second + a2 * first + a3 * v3
        first = 2 * v1 - first
        second = 2 * v2 - second
        let variance = 2 * g / ((1 + g) * (1 + g))
        return k * v1 / variance.squareRoot()
    }
}
