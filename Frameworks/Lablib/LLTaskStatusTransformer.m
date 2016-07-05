//
//  LLTaskStatusTransformer.m
//  Lablib
//
//  Created by John Maunsell on January 29, 2005.
//  Copyright 2005. All rights reserved.
//

#import "LLTaskStatusTransformer.h"
#import "LLStandardDataEvents.h"

@implementation LLTaskStatusTransformer

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
//	long mode;
	
    if (value == nil) {
		return nil;
	}

// Attempt to get a reasonable value from the 
// value object. 

    if (![value respondsToSelector: @selector(intValue)]) {
//        mode = [value intValue];		 // handles NSString and NSNumber
//    } else {
        [NSException raise: NSInternalInconsistencyException
				format: @"LLTaskStatusTransformer: Value (%@) does not respond to -floatValue.",
			[value class]];
    }
    
	switch (type) {
	case kLLTaskStatusIdle:
		number = [NSNumber numberWithBool:
				(([value intValue] & kLLTaskModeMask) == kTaskIdle)];
		break;
	case kLLTaskStatusIdleAndNoFile:
		number = [NSNumber numberWithBool:
				((([value intValue] & kLLTaskModeMask) == kTaskIdle) &&
				(!([value intValue] & kLLFileOpenMask)))];
		break;
	case kLLTaskStatusNoFile:
		number = [NSNumber numberWithBool:
				(!([value intValue] & kLLFileOpenMask))];
		break;
	}
	return number;
}

@end
