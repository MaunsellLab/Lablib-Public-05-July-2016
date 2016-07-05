/*
 *  LLDistribution.h
 *  Lablib
 *  
 *  Protocol specifying required methods for a statistical distribution
 *
 *  Created by John Maunsell on Fri Sep 24 2004.
 *  Copyright (c) 2004. All rights reserved.
 *
 */

enum {kStandardError, kConfidence95};

#define kConfidence68		kStandardError
#define k68ErrorCriterion	((1.0 - 0.6826) / 2.0)

@protocol LLDistribution

- (void)addValue:(double)value;
- (void)clear;
- (double)lowerError;
- (double)mean;
- (double)n;
- (double)se;
- (void)setErrorType:(long)errorType;
- (double)std;
- (void)subtractValue:(double)value;
- (double)upperError;
- (double)var;

@end