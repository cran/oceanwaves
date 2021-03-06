
<!-- README.md is generated from README.Rmd. Please edit that file -->

[![DOI](https://zenodo.org/badge/85914597.svg)](https://zenodo.org/badge/latestdoi/85914597)

`oceanwaves` provides a set of functions to calculate summary statistics
for ocean waves, using a record of sea surface elevation as input. For
sea surface elevations derived from bottom-mounted pressure transducers,
the package also contains a function `prCorr()` to correct for depth
attenuation of the pressure signal, and the `swDepth()` function from
the package `oce` can be used to convert pressure data into ocean
surface elevations (see the included package vignette).

`waveStatsSP()` produces wave height and period statistics using
spectral analysis methods, while `waveStatsZC()` calculates additional
wave height and period statistics based on a zero-crossing algorithm.

See the package vignette for example workflows to proceed from raw
pressure data to summary wave statistics.

Pressure corrections and wave statistics functions were adapted from Urs
Neumeier’s `waves` functions for MATLAB, developed from earlier work by
Travis Mason and Magali Lecouturier.
<http://neumeier.perso.ch/matlab/waves.html>

To install the development version of this package from within R, first
install the package `devtools`
<https://CRAN.R-project.org/package=devtools> and then install this
package from Github:

``` r
install.packages('devtools')
library(devtools)
install_github('millerlp/oceanwaves')
```
