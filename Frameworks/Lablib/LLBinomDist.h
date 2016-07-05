//
//  LLBinomDist.h
//  Lablib
//
//  Created by John Maunsell on Sep 24, 2004.
//  Copyright 2004. All rights reserved.
//

#import "LLDistribution.h"

@interface LLBinomDist : NSObject <LLDistribution> {

@protected
long	errorType;
double 	n;
double	sum;
double	sumsq;

}

@end
