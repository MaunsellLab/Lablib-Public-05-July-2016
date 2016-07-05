//
//  LLMultiplierTransformer.m
//  Lablib
//
//  Created by John Maunsell on 12/18/04.
//  Copyright 2004. All rights reserved.
//
// Transform a value by a multiplier

#import "LLMultiplierTransformer.h"

@implementation LLMultiplierTransformer

+ (BOOL)allowsReverseTransformation;
{
    return YES;   
}

+ (Class)transformedValueClass;
{
    return [NSNumber class];
}

- (id)init;
{
	if ((self = [super init])) {
		multiplier = 100.0;
	}
	return self;
}
		 
- (float)multiplier;
{
	return multiplier;
}

- (id)reverseTransformedValue:(id)value;
{
	float outputValue;
	
    if (value == nil) {
		return nil;
	}
    
// Attempt to get a reasonable value from the 
// value object. 

    if ([value respondsToSelector: @selector(floatValue)]) {
        outputValue = [value floatValue];			  // handles NSString and NSNumber
    } 
	else {
        [NSException raise: NSInternalInconsistencyException
				format: @"LLMultiplierTransformer: Value (%@) does not respond to -floatValue.",
				[value class]];
		return nil;
    }
    return [NSNumber numberWithFloat:outputValue / multiplier];
}

- (void)setMultiplier:(float)newMultiplier;
{
	multiplier = newMultiplier;
}

- (id)transformedValue:(id)value;
{
    float inputValue;

    if (value == nil) {
		return nil;
	}

// Attempt to get a reasonable value from the 
// value object. 

    if ([value respondsToSelector: @selector(floatValue)]) {
        inputValue = [value floatValue];		 // handles NSString and NSNumber
    } else {
        [NSException raise: NSInternalInconsistencyException
				format: @"LLMultiplierTransformer: Value (%@) does not respond to -floatValue.",
			[value class]];
		return nil;
    }
    
// Compute the steps per octave from the factor

    return [NSNumber numberWithFloat:inputValue * multiplier];
}

@end
