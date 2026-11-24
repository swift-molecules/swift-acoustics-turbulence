# swift-acoustics-turbulence

Use this package when a sound comes from moving air: a wire or twig whistling its aeolian tone, the gusts that bend that tone, and the broadband rush of a thicket of many twigs at once. Start from `Acoustics.Turbulence.Wind`, a gust (`Acoustics.Turbulence.Gust`) and the bodies in it (`Acoustics.Turbulence.Body`, each a `Cylinder` at a distance, or `.thicket(…)`), and read its sound pressure with `pressures(count:interval:)`.

## Laws

- The Reynolds number is U d / ν, with ν the air's viscosity over its density (Reynolds 1883).
- The Strouhal number St = f d / U is Roshko's (1954, NACA Report 1191): 0.212 − 4.5 / Re from 40 to 150, 0.212 − 2.7 / Re above; below 40 no vortices are shed and there is no tone. From 60 to 120 it agrees with Williamson and Brown's (1998) series to 1%, and to 3% at the ends of the range.
- A cylinder's tone is Curle's (1955) compact dipole of its fluctuating lift, ½ ρ U² d C′L per length, with lengths further apart than the correlation length Λ adding in power (Phillips 1956): p_rms = St ρ U³ C′L cos θ √(L min(L, Λ)) / (4 c r). Its intensity goes as U⁶, 18.06 dB for each doubling of the wind at a steady Strouhal number.
- C′L and Λ are given, never assumed: both depend on the Reynolds number (Norberg 2003 reviews the measurements).
- Gusts have von Kármán's spectrum, S(f) = 4 σ² (L / U) / (1 + 70.8 (f L / U)²)^(5/6) (IEC 61400-1): it integrates to σ² to 0.1%, and falls as f^(−5/3). A realization is Shinozuka and Deodatis's (1991) sum of cosines over bands spaced evenly in log frequency, with phases from swift-threefry, so the same seed gives the same wind everywhere.
- `pressures` reads the gust every 32 samples; each body's tone takes that speed's shedding frequency and glides to its amplitude, √2 p_rms. A tone at or above half the sampling rate is silent. A wire in steady wind measures at its shedding frequency to 0.1% and its level to 1%.
