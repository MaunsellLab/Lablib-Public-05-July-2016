//
//  SCRoundToStimCycle.m
//  SpotChange
//
//  Created by Incheol Kang on 3/6/07.
//  Copyright 2007. All rights reserved.
//

#import "SC.h"
#import "SCRoundToStimCycle.h"

@implementation SCRoundToStimCycle

+ (Class)transformedValueClass;
{ 
	return [NSNumber class]; 
}

+ (BOOL)allowsReverseTransformation;
{
	return YES;
}

- (id)reverseTransformedValue:(id)value;
{
	long stimulusMS, interstimMS;
	float output;
	
	stimulusMS = [[task defaults] integerForKey:SCStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:SCInterstimMSKey];
	
	output = round((float)[value longValue] / (stimulusMS + interstimMS)) * (stimulusMS + interstimMS);
    return [NSNumber numberWithLong:output];
}

- (id)transformedValue:(id)value;
{
	long output;
	output = [value longValue];
	return [NSNumber numberWithLong:output];
}

@end
