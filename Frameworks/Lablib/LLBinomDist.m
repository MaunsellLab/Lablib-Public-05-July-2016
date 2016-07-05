//
//  LLBinomDist.m
//  Lablib
//
//  Created by John Maunsell on Sep 24, 2004.
//  Copyright 2004. All rights reserved.
//
//  f(x) = (n!  / (x! * (n-x)!)) * p^x * (1-p)^(n-x)

#import "LLBinomDist.h"

#define dMean			(sum / n)
#define dSD				(sqrt(dVar))
#define dVar			(sum * (1 - sum / n)) / (n * n)
#define dSE				(sqrt(((sumsq - sum * sum / n) / (n - 1.0)) / n))

#define kLimit	50

static BOOL initialized = NO;

static float p68Lower[kLimit][kLimit + 1];					// cutoff n for 0.68 dist by [n][x]
static float p68Upper[kLimit][kLimit + 1];					// cutoff n for 0.68 dist by [n][x]

@implementation LLBinomDist

- (void)addValue:(double)value  {

	n += 1.0;
	if (value != 0) {
		sum += 1.0;
		sumsq += 1.0;
	}
}

- (void) clear {

    n = sum = sumsq = 0.0;
}

// We fill lookup tables with the cutoff probabilities associated with a statistic criterion
// and a given number of samples and hits.  These entries are read by upperLimit and lowerLimit

-(id)init {

	long nn, xx, x, p;
	double baseProb, prob, probSum, logP, logOneMinusP, factorial[kLimit];
	
    if ((self = [super init]) != nil) {
		errorType = kConfidence68;
		if (!initialized) {
			initialized = YES;
			factorial[0] = 1.0;
			for (nn = 1; nn < kLimit; nn++) {
				factorial[nn] = factorial[nn - 1] * nn;
			}
			for (nn = 1; nn < kLimit; nn++) {				// for each number of samples
				for (xx = 0; xx <= nn; xx++) {				// for each number successes
					baseProb = (double)xx / nn;
					for (p = floor(100 * baseProb) + 1; p < 100; p++) {
						logP = log(p / 100.0);
						logOneMinusP = log(1.0 - p / 100.0);
						for (x = probSum = 0; x <= xx; x++) {
							prob = factorial[nn] / (factorial[x] * factorial[nn - x]) *
									exp(logP * x) * exp(logOneMinusP * (nn - x));
							probSum += prob;
						}
						if (probSum < k68ErrorCriterion) {
							break;
						}
					}
					p68Upper[nn][xx] = MIN(p / 100.0, 1.0);

					for (p = ceil(100 * baseProb) - 1; p > 0; p--) {
						logP = log(p / 100.0);
						logOneMinusP = log(1.0 - p / 100.0);
						for (x = nn, probSum = 0.0; x >= xx; x--) {
							prob = factorial[nn] / (factorial[x] * factorial[nn - x]) *
									exp(logP * x) * exp(logOneMinusP * (nn - x));
							probSum += prob;
						}
						if (probSum < k68ErrorCriterion) {
							break;
						}
					}
					p68Lower[nn][xx] = MAX(p / 100.0, 0.0);
				}
			}
		}
    }
    return self;
}

- (double)lowerError {

	double lowerError;
	
	switch (errorType) {
	case kConfidence68:
	default:
		if (n < 1) {							// no samples return 0
			lowerError = 0.0;
		}
		else if (n < kLimit) {
			lowerError = p68Lower[(long)n][(long)sum];
		}
		else {
			lowerError = MAX(0.0, dMean - dSE);
		}
		break;
	}
	return lowerError;
}

- (double) mean {

    return dMean;
}

- (double)n {

    return n;
}

- (double)se {

	double approximateSE;
	long tempErrorType = errorType;
	
	errorType = kConfidence68;
	approximateSE = ([self upperError] + [self lowerError]) / 2.0;
	errorType = tempErrorType;
	return approximateSE;
}

- (void)setErrorType:(long)type {

	errorType = type;
}

- (double)std {

    if (n < 1) {
        return 0.0;
    }
    else {
        return dSD;
    }
}

- (void) subtractValue:(double)value {

	n -= 1.0;	
	if (value != 0) {
		sum -= 1.0;
		sumsq -= 1.0;
	}
}

- (double) var {

    if (n < 1) {
        return 0.0;
    }
    else {
        return dVar;
    }
}

- (double)upperError {

	double upperError;
	
	switch (errorType) {
	case kConfidence68:
	default:
		if (n < 1) {							// no samples return 0
			upperError = 0.0;
		}
		else if (n < kLimit) {
			upperError = p68Upper[(long)n][(long)sum];
		}
		else {
			upperError = MIN(1.0, dMean + dSE);
		}
		break;
	}
	return upperError;
}

@end
