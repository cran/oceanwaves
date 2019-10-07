## ---- include = FALSE----------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----install, eval=FALSE-------------------------------------------------
#  install.packages('oceanwaves')

## ----setup---------------------------------------------------------------
library(oceanwaves)

## ----loadData------------------------------------------------------------
data(wavedata)

## ----headWavedata--------------------------------------------------------
options(digits.sec = 3)  # print fractional seconds
head(wavedata)

## ----subtractAirPressure-------------------------------------------------
surfacepressure.mbar = wavedata$absPressure.mbar - 1014

## ----convertdecibar------------------------------------------------------
surfacepressure.dbar = surfacepressure.mbar / 100

## ----convertswDepth------------------------------------------------------
swDepth.m = oce::swDepth(surfacepressure.dbar, latitude = 33.75)

## ----pressCorr-----------------------------------------------------------
swDepthCorrected.m = prCorr(swDepth.m, Fs = 4, zpt = 0.1)

## ---- fig.width = 8, fig.height = 4--------------------------------------
plot(swDepthCorrected.m, type = 'l', col = 'red', 
     ylab = 'Surface elevation, m')
lines(swDepth.m, col = 'blue')
legend('topright',legend=c('Corrected','Raw'), col = c('red','blue'),
       lty = 1)

## ----ZC------------------------------------------------------------------
zerocrossStats = waveStatsZC(swDepthCorrected.m, Fs = 4)
zerocrossStats

## ------------------------------------------------------------------------
spectralStats = waveStatsSP(swDepthCorrected.m, Fs = 4)
spectralStats

## ----zcPlot, fig.width = 6, fig.height = 6, results = 'hide'-------------
waveStatsZC(swDepthCorrected.m, Fs = 4, plot = TRUE)

## ----spPlot, fig.width = 8, fig.height = 4, results = 'hide'-------------
waveStatsSP(swDepthCorrected.m, Fs = 4, plot = TRUE)

