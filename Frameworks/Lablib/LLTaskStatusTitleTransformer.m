//
//  LLTaskStatusTitleTransformer.m
//  Lablib
//
//  Created by John Maunsell on 12/27/04.
//  Copyright 2004. All rights reserved.
//

#import "LLTaskStatusTitleTransformer.h"
#import "LLStandardDataEvents.h"

@implementation LLTaskStatusTitleTransformer

+ (Class)transformedValueClass;
{
    return [NSString class];
}

- (id)transformedValue:(id)value;
{
	long mode = 0;
	NSString *title;
	
    if (value == nil) {
		return nil;
	}

// Attempt to get a reasonable value from the 
// value object. 

    if ([value respondsToSelector: @selector(intValue)]) {
        mode = ([value intValue] & kLLTaskModeMask);		 // handles NSString and NSNumber
    } 
	else {
        [NSException raise: NSInternalInconsistencyException
				format: @"LLTaskStatusTitleTransformer: Value (%@) does not respond to -floatValue.",
			[value class]];
    }
    
// Return the correct control title for the current task mode

	switch (mode) {
	case kTaskIdle:
		title = @"Run";
		break;
	case kTaskRunning:
		title = @"Stop";
		break;
	case kTaskStopping:
		title = @"Stop Now";
		break;
	default:
		title = @"----";
		break;
	}
	return title;
}


@end
