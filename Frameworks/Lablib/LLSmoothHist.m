//
//  LLSmoothHist.m
//  Lablib
//
//  Created by John Maunsell on Sun Jun 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLSmoothHist.h"


@implementation LLSmoothHist

+ (double)smoothHist:(double *)hist bins:(long)bins sigma:(double)sigma filter:(short)filter {

	long index, bin, gindex;
	double *temp;
	long glength, gHalfDown, gHalfUp;
	double kernel[kLLFilterMax];
	double maxbin, sigmaSq;
	double x, sum;
	double factor;

	if (bins <= 0) {
		return 0.0;
	}
	if (sigma <= 0.0) {
		for (bin = maxbin = 0; bin < bins; bin++) {
			maxbin = MAX(maxbin, hist[bin]);
		}
		return maxbin;
	}
		
	glength = 0;
	switch (filter) {

// Set up the Gaussian function.  Only compute 1/2 the function, it's mirror symmetric.
// About 2.5 * sigma is the right number to get to values that are less than 1% of the
// peak value.  The truncated distribution is normalized so that its area is 1.0,
// and there is no net change on the area under the histogram when it is changed.

	case kLLGaussian:
		glength = MIN(sigma * 5.0, kLLFilterMax);
		sigmaSq = sigma * sigma;
		for (index = sum = 0; index < glength; index++) {
			x = index - glength / 2.0;
			kernel[index] = exp((-(x * x) / sigmaSq));
			sum += kernel[index];
		}
		factor = 1.0 / sum;
		for (index = 0; index < glength; index++) {
			kernel[index] *= factor;
		}
		break;

// Set up the exponential function.  About 2.5 * sigma is the right number to get to
// values that are less than 1% of the peak value.  The truncated distribution is
// normalized so that its area is 1.0, and there is no net change on the area under
// the histogram when it is changed.

	case kLLExponential:
		glength = MIN(sigma * 5.0, kLLFilterMax);
		for (index = sum = 0; index < glength / 2; index++) {
			x = index - glength / 2.0;
			kernel[index] = exp((x / sigma));
			sum += kernel[index];
		}
		factor = 1.0 / sum;
		for (index = 0; index < glength / 2; index++) {
			kernel[index] *= factor;
		}
		for (index = glength / 2; index < glength; index++) {
			kernel[index] = 0.0;
		}
		break;

	case kLLBoxCar:
		glength = MIN(sigma, kLLFilterMax);
		for (index = 0; index < glength; index++) {
			kernel[index] = 1.0 / glength;
		}
		break;

	case kLLBin:
	default:
		break;
	}

// Construct the smoothed histogram.

	if (filter == kLLBin) {
		for (bin = maxbin = 0; bin < bins; bin += sigma) {
			for (index = bin, sum = 0.0; index < MIN(bin + sigma, bins); index++) {
				sum += hist[index];
			}
			sum /= (index - bin);
			for (index = bin; index < MIN(bin + sigma, bins); index++) {
				hist[index] = sum;
			}
			maxbin = MAX(maxbin, sum);
		}
	}
	else {
		gHalfDown = glength / 2;
		gHalfUp = (glength + 1) / 2;
		if ((temp = (double *)calloc(bins, sizeof(double))) == NULL) {
			// ??? Fatal exit
		}

// We need special effort at the start of the histogram so that the smoothing window
// does not go before the start of the histogram

		for (bin = 0; bin < MIN(gHalfUp, bins); bin++) {
			gindex = factor = 0;
			index = bin - gHalfDown;
			while (index < 0) {
				index++;
				gindex++;
			}
			while (index < bin + gHalfUp) {
				temp[bin] += hist[index] * kernel[gindex];
				factor += kernel[gindex];
				index++;
				gindex++;
			}
			temp[bin] *= 1.0 / factor;			// compensate for using only part of kernel
		}	

// Load the main part of the histogram more than a half-filterwidth from the edges

		for ( ; bin < bins - gHalfUp; bin++) {
			index = bin - gHalfDown;
			gindex = 0;
			while (index < bin + gHalfUp) {
				temp[bin] += hist[index] * kernel[gindex];
				index++;
				gindex++;
			}
		}
		
// We need special effort at the end of the histogram so that the smoothing window
// does not go before the end of the histogram

		for ( ; bin < bins; bin++) {
			gindex = factor = 0;
			index = bin - gHalfDown;
			while (index < bins) {
				temp[bin] += hist[index] * kernel[gindex];
				factor += kernel[gindex];
				index++;
				gindex++;
			}
			temp[bin] *= 1.0 / factor;			// compensate for using only part of kernel
		}	

// Copy the histogram over, and find the maximum bin

		for (bin = maxbin = 0; bin < bins; bin++) {
			hist[bin] = temp[bin];
			maxbin = MAX(maxbin, hist[bin]);
		}
		free((void *)temp);
	}
	return maxbin;
}

@end
