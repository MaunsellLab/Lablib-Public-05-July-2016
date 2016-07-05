//
//  LLPointDist.m
//  Lablib
//
//  Created by John Maunsell on 4/21/07.
//  Copyright 2007. All rights reserved.
//
// LLPointDist isn't a distribution at all, it is just a value with upper and lower
// confidence intervals (errors).  It exists to simplify plotting, where LLPlotView
// expects to receive an NSArray containing <LLDistribution> objects.  Using LLPointDist,
// you can get LLPlotView to plot a line with error bars, even if you don't have a 
// real distribution 

#import "LLPointDist.h"

@implementation LLPointDist

- (void)addValue:(double)newValue;
{
	value = newValue;
	n = 1.0;
}

- (void)clear;
{
	n = value = lowerError = upperError = 0;
}

- (double)lowerError;
{
	return lowerError;
}

- (double)mean;
{
	return value;
}

- (double)n;
{
	return n;
}

- (double)se;
{
	return fabs(upperError + lowerError) / 2.0;
}
	
- (void)setErrorType:(long)errorType;
{
}

// We don't know about standard errors, only the (undefined) confidence interval

- (void)setLowerError:(double)newError;
{
	lowerError = newError;
}

- (void)setUpperError:(double)newError;
{
	upperError = newError;
}

- (double)std;
{
	return 0.0;
}

- (void)subtractValue:(double)value;
{
}

- (double)upperError;
{
	return upperError;
}

- (double)var;
{
	return 0.0;
}

@end
