//
//  LLPointDist.h
//  Lablib
//
//  Created by John Maunsell on 4/21/07.
//  Copyright 2007. All rights reserved.
//

#import "LLDistribution.h"

@interface LLPointDist : NSObject  <LLDistribution> {

	double lowerError;
	double 	n;
	double upperError;
	double	value;
	double	sum;
	double	sumsq;

}

- (void)setLowerError:(double)newError;
- (void)setUpperError:(double)newError;

@end
