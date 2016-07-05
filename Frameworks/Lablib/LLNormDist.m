//
//  LLNormDist.m
//  Lablib
//
//  Created by John Maunsell on Fri May 09 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLNormDist.h"

#define dMean	(sum / n)
#define dSD		(sqrt(dVar))
#define dSE		(sqrt(dVar / n))
#define dVar	((sumsq - sum * sum / n) / (n - 1.0))

@implementation LLNormDist

- (void)addValue:(double)value;
{
    n += 1.0;
    sum += value;
    sumsq += value * value;
}

- (void) clear;
{
    n = sum = sumsq = 0.0;
}


- (double)lowerError;
{
	double lowerError = dMean;
	
	switch (errorType) {
	case kStandardError:
	default:
		if (n >= 2) {
			lowerError = dMean - dSE;
		}
		break;
	}
	return lowerError;
}

- (double) mean;
{
    return dMean;
}

- (double)n;
{
    return n;
}

- (double)se;
{
    if (n < 2) {
        return 0.0;
    }
    else {
        return dSE;
    }
}

- (void)setErrorType:(long)type;
{
	errorType = type;
}

- (double)std;
{
    if (n < 2) {
        return 0.0;
    }
    else {
        return dSD;
    }
}

- (void) subtractValue:(double)value;
{
    n -= 1.0;
    sum -= value;
    sumsq -= value * value;
}

- (double) var;
{
    if (n < 2) {
        return 0.0;
    }
    else {
        return dVar;
    }
}

- (double)upperError;
{
	double upperError = dMean;
	
	switch (errorType) {
	case kStandardError:
	default:
		if (n >= 2) {
			upperError = dMean + dSE;
		}
		break;
	}
	return upperError;
}

@end
