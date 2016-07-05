//
//  LLNullDataDevice.m
//  Lablib
//
//  Created by John Maunsell on 12/24/05.
//  Copyright 2005. All rights reserved.
//

#import "LLNullDataDevice.h"

#define kLLNullSamplePeriodMS		1
#define kLLNullTimestampPeriodMS	1

@implementation LLNullDataDevice

- (void)disableSampleChannels:(NSNumber *)bitPattern;
{
}

- (void)disableTimestampChannels:(NSNumber *)bitPattern;
{
}

- (void)enableSampleChannels:(NSNumber *)bitPattern;
{
}

- (void)enableTimestampChannels:(NSNumber *)bitPattern;
{
}

- (id)init;
{
    if ((self = [super init]) != nil) {
		[samplePeriodMS addObject:[NSNumber numberWithFloat:kLLNullSamplePeriodMS]];
		[timestampPeriodMS addObject:[NSNumber numberWithLong:kLLNullTimestampPeriodMS]];
		devicePresent = YES;
    }
    return self;
}

- (NSString *)name
{
	return @"None";
}

- (long)sampleChannels;
{
	return LONG_MAX;
}

- (float)samplePeriodMSForChannel:(long)channel;
{
	return 1.0;
}

- (BOOL)setSamplePeriodMS:(float)newPeriodMS channel:(long)channel;
{
	return YES;
}

- (BOOL)setTimestampTicksPerMS:(long)newTicksPerMS channel:(long)channel;
{
	return YES;
}

- (long)timestampChannels;
{
	return LONG_MAX;
}

- (float)timestampSamplePeriodMSForChannel:(long)channel;
{
	return 1.0;
}

- (long)timestampTicksPerMSForChannel:(long)channel;
{
	return 1;
}

@end
