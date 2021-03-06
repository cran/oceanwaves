#' Calculate ocean wave parameters using spectral analysis methods
#' 
#' Calculate ocean wave parameters using spectral analysis methods
#' 
#' Carries out spectral analysis of ocean wave height time series to estimate
#' common wave height statistics, including peak period, average period, 
#' and significant wave height.
#' 
#' @param data A vector of surface heights that constitute a time series of 
#' observations. Typical units = meters.
#' @param Fs Sampling frequency of the surface heights data. Units = Hz, i.e.
#' samples per second.
#' @param method A character string indicating which spectral analysis method
#' should be used. Choose one of \code{welchPSD} (default) or \code{spec.pgram}.
#' @param kernel An object of class \code{tskernel} that defines a smoother for use
#' with \code{spec.pgram} method. If value is \code{NULL}, a default Daniell kernel with 
#' widths (9,9,9) is used.
#' @param segments Numeric value indicating the number of windowing segments to
#' use with \code{welchPSD} method.
#' @param plot A logical value denoting whether to plot the spectrum. Defaults 
#' to \code{FALSE}. 
#' @param ... Additional arguments to be passed to spectral analysis functions, 
#' such as the \code{windowfun} option for \code{welchPSD}.
#' 
#' @return List of wave parameters based on spectral methods.
#' \itemize{
#'   \item \code{h} Average water depth. Same units as input surface heights 
#'   (typically meters).
#' 
#'   \item \code{Hm0} Significant wave height based on spectral moment 0. Same
#'   units as input surface heights (typically meters).
#'   This is approximately equal to the average of the highest 1/3 of the waves.
#' 
#'   \item \code{Tp} Peak period, calculated as the frequency with maximum power 
#'   in the power spectrum. Units of seconds.
#' 
#'   \item \code{m0} Estimated variance of time series (moment 0).
#' 
#'   \item \code{T_0_1} Average period calculated as \eqn{m0/m1}, units seconds. Follows National 
#'   Data Buoy Center's method for average period (APD).
#' 
#'   \item \code{T_0_2} Average period calculated as \eqn{(m0/m2)^0.5}, units seconds. Follows 
#'   Scripps Institution of Oceanography's method for calculating average period 
#'   (APD) for their buoys.
#' 
#'   \item \code{EPS2} Spectral width parameter.
#' 
#'   \item \code{EPS4} Spectral width parameter.
#' }
#' 
#' @references Original MATLAB function by Urs Neumeier:  
#' http://neumeier.perso.ch/matlab/waves.html, based on code developed by Travis 
#' Mason, Magali Lecouturier and Urs Neumeier.
#' @seealso \code{\link{waveStatsZC}} for wave statistics determined using a 
#' zero-crossing algorithm. 
#' @export
#' @importFrom stats spec.pgram ts
#' @importFrom bspec welchPSD
#' @examples
#' data(wavedata)
#' waveStatsSP(wavedata$swDepth.m, Fs = 4, method = 'spec.pgram', plot = TRUE)

waveStatsSP <- function(data, Fs, method = c('welchPSD', 'spec.pgram'), 
		 plot = FALSE, kernel = NULL, segments = NULL, ...){

	method <- match.arg(method, choices = c('welchPSD','spec.pgram'))
	
	# minimum frequency, below which no correction is applied (0.05 = 20 seconds)
	min_frequency <- 0.05;	
	# maximum frequency, above which no correction is applied (0.33 = ~3seconds)
	max_frequency <- 0.33;			

	# Prepare data for spectral analysis
	
	m <- length(data);		# Get length of surface height record

	#####################
	h <- mean(data);			#% mean water depth
	
	# Call oceanwaves::detrendHeight() 
	# Function that computes the least-squares fit of a straight line to 
	# the data and subtracts the resulting function from the data. The resulting
	# values represent deviations of surface height from the mean surface 
	# height in the time series.
	detrended <- oceanwaves::detrendHeight(data); 
	data <- detrended[['pt']][] # Extract vector of detrended surface heights
	
	# Convert timeseries of surface heights to a timeseries object
	xt <- stats::ts(data, frequency = Fs)
	
	if (method == 'spec.pgram'){
		if (is.null(kernel)){
			kernelval <- kernel('daniell', c(9,9,9)) # Set default
		} else if (class(kernel) == 'tskernel') {
			kernelval <- kernel # Use the user's kernel values
		} else {
			stop("Kernel for spec.pgram must be of class 'tskernel'")
		}
		# Use spec.pgram to estimate power spectral density, with smoothers
		pgram <- stats::spec.pgram(xt, kernel = kernelval, taper=0.1, plot=FALSE)
		pgramm0 <- (Fs * mean(pgram$spec))
		deltaf <- pgram$freq[2] - pgram$freq[1] # bandwidth (Hz)
		integmin <- min(which(pgram$freq >= 0)); # this influences Hm0 and other wave parameters
		integmax <- max(which(pgram$freq <= max_frequency * 1.5 ));
		moment <- vector(length = 7)
		# Calculate moments of the spectrum, from -2nd to 0th to 4th
		# For a spectrum, the 0th moment represents the variance of the data, and
		# should be close to the value produced by simply using var(data)
		for (i in seq(-2, 4, by = 1)) { # calculation of moments of spectrum
			# Note that the pgram$spec values are multiplied by 2 to normalize them
			# in the same fashion as a raw power spectral density estimator
			moment[i+3] <- sum(pgram$freq[integmin:integmax]^i*
							(2 * pgram$spec[integmin:integmax])) * deltaf;
		}	
		# Peak period, calculated from Frequency at maximum of spectrum 
		Tp <- 1 / pgram$freq[which.max(pgram$spec)] # units seconds
	} else if (method == 'welchPSD'){
		if (is.null(segments)){
			# Set default segment length for windowing
			Noseg <- 4
		} else {
			Noseg <- segments
		} 
		M <- 2 * (length(data)/ (Noseg+1)) / Fs
		seglength <-  M
		
		wpsd <- bspec::welchPSD(xt, seglength = M, two.sided = FALSE, 
				method = 'mean',
				windowingPsdCorrection = TRUE, ...)
		# Remove the zero-frequency entry
		wpsd$frequency <- wpsd$frequency[-1]
		# Remove the zero-frequency entry from power as well
		wpsd$power <- wpsd$power[-1] 
		
		deltaf <- wpsd$frequency[2]-wpsd$frequency[1] # delta-frequency
		integmin <- min(which(wpsd$frequency >= 0)); # this influences Hm0 and other wave parameters
		integmax <- max(which(wpsd$frequency <= max_frequency * 1.5 ));
		moment <- vector(length = 7)
		# Calculate moments of the spectrum, from -2nd to 0th to 4th
		# For a spectrum, the 0th moment represents the variance of the data, and
		# should be close to the value produced by simply using var(data)
		for (i in seq(-2, 4, by = 1)) { # calculation of moments of spectrum
			# Note that the wpsd$power values are multiplied by 2 to normalize them
			# in the same fashion as a raw power spectral density estimator
			moment[i+3] <- sum(wpsd$frequency[integmin:integmax]^i *
							(wpsd$power[integmin:integmax])) * deltaf;
		}
		# Peak period, calculated from Frequency at maximum of spectrum 
		Tp <- 1 / wpsd$frequency[which.max(wpsd$power)]  # units seconds
	}
	
	# Estimated variance of time series (moment 0)
	m0 <- moment[3]; 
	# Estimate significant wave height based on spectral moment 0, units meters
	# This value is approximately equal to the average of the highest one-third
	# of waves in the time series.  
	Hm0 <- 4 * sqrt(m0) 
	# T_0_1, average period m0/m1, units seconds. Follows National Data Buoy
	# Center's method for average period (APD)
	T_0_1 <- moment[3] / moment[1+3] 
	# T_0_2, average period (m0/m2)^0.5, units seconds. Follows Scripp's 
	# Institute of Oceanography's method for calculating average period (APD)
	# for their buoys. 
	T_0_2 <- (moment[0+3] / moment[2+3])^0.5

	# spectral width parameters
	EPS2 <- (moment[0+3] * moment[2+3] / moment[1+3]^2 - 1)^0.5
	EPS4 <- (1 - moment[2+3]^2 / (moment[0+3]*moment[4+3]) )^0.5

	results <- list(h = h, Hm0 = Hm0, Tp = Tp, m0 = m0, T_0_1 = T_0_1,
			T_0_2 = T_0_2, EPS2 = EPS2, EPS4 = EPS4)
	
	if (plot){
		if (method == 'welchPSD'){
			freqspec <- data.frame(freq = wpsd$frequency, spec = wpsd$power)	
		} else if (method == 'spec.pgram'){
			# Multiply pgram spectrum by 2 to normalize
			freqspec <- data.frame(freq = pgram$freq, spec = 2 * pgram$spec)
		}
		oceanwaves::plotWaveSpectrum(freqspec, Fs)
	}
		
	results # Return data frame
}

################################################################################

