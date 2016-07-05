//
//  LLTaskModeTransformer.m
//  Lablib
//
//  Created by John Maunsell on 12/28/04.
//  Copyright 2004. All rights reserved.
//

#import "LLTaskModeTransformer.h"
#import "LLStandardDataEvents.h"

@implementation LLTaskModeTransformer

+ (Class)transformedValueClass;
{
    return [NSNumber class];
}

- (void)setTransformerType:(long)newType;
{
	type = newType;
}

- (id)transformedValue:(id)value;
{
	NSNumber *number = nil;
	
    if (value == nil) {
		return nil;
	}

// Attempt to get a reasonable value from the 
// value object. 

    if (![value respondsToSelector: @selector(intValue)]) {
        [NSException raise: NSInternalInconsistencyException
				format: @"LLTaskModeTransformer: Value (%@) does not respond to -floatValue.",
			[value class]];
    }
    
	switch (type) {
	case kLLTaskModeIdle:
		number = [NSNumber numberWithBool:
				(([value intValue] & kLLTaskModeMask) == kTaskIdle)];
		break;
	case kLLTaskModeIdleAndNoFile:
		number = [NSNumber numberWithBool:
				((([value intValue] & kLLTaskModeMask) == kTaskIdle) &&
				(!([value intValue] & kLLFileOpenMask)))];
		break;
	case kLLTaskModeNoFile:
		number = [NSNumber numberWithBool:
				(!([value intValue] & kLLFileOpenMask))];
		break;
	}
	return number;
}

@end
