//
//  LLFactorToOctaveStepTransformer.m
//  Experiment
//
//  Created by John Maunsell on 12/9/04.
//  Copyright 2004. All rights reserved.
//
// Compute the number of steps in an octave that will result from a given 
// proportionality factor (<1.0).

#import "LLFactorToOctaveStepTransformer.h"

@implementation LLFactorToOctaveStepTransformer

+ (BOOL)allowsReverseTransformation;
{
    return YES;   
}

+ (Class)transformedValueClass;
{
    return [NSNumber class];
}

- (id)reverseTransformedValue:(id)value;
{
	float factor;
    float stepsPerOctave = 1;

    if (value == nil) {
		return nil;
	}
    
// Attempt to get a reasonable value from the 
// value object. 

    if ([value respondsToSelector: @selector(floatValue)]) {
        stepsPerOctave = [value floatValue];			  // handles NSString and NSNumber
    } 
	else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"LLFactorToOctaveStepTransformer: Value (%@) does not respond to -floatValue.",
					[value class]];
    }
    
// calculate factor

	factor = 1.0 / exp((log(2.0) / stepsPerOctave));
    return [NSNumber numberWithDouble:factor];
}

- (id)transformedValue:(id)value;
{
    float factor = 1.0;
	float stepsPerOctave;

    if (value == nil) {
		return nil;
	}

// Attempt to get a reasonable value from the 
// value object. 

    if ([value respondsToSelector: @selector(floatValue)]) {
        factor = [value floatValue];		 // handles NSString and NSNumber
    } else {
        [NSException raise: NSInternalInconsistencyException
				format: @"LLFactorToOctaveStepTransformer: Value (%@) does not respond to -floatValue.",
			[value class]];
    }
    
// Compute the steps per octave from the factor

	stepsPerOctave = log(2.0) / log(1.0 / factor);
    return [NSNumber numberWithFloat: stepsPerOctave];
}

@end
