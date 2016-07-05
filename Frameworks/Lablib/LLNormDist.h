//
//  LLNormDist.h
//  Lablib
//
//  Created by John Maunsell on Fri May 09 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLDistribution.h"

@interface LLNormDist : NSObject  <LLDistribution> {

long	errorType;
double 	n;
double	sum;
double	sumsq;

}

@end
