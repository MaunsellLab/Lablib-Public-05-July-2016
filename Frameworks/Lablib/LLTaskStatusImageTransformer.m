//
//  LLTaskStatusImageTransformer.m
//  Lablib
//
//  Created by John Maunsell on 12/27/04.
//  Copyright 2004. All rights reserved.
//

#import "LLTaskStatusImageTransformer.h"
#import "LLStandardDataEvents.h"


@implementation LLTaskStatusImageTransformer

+ (Class)transformedValueClass;
{
    return [NSImage class];
}

- (id)transformedValue:(id)value;
{
	long mode = 0;
	NSImage *image;
	
    if (value == nil) {
		return nil;
	}

// Attempt to get a reasonable value from the 
// value object. 

    if ([value respondsToSelector: @selector(intValue)]) {
        mode = ([value intValue] & kLLTaskModeMask);		 // handles NSString and NSNumber
    } else {
        [NSException raise: NSInternalInconsistencyException
				format: @"LLTaskStatusImageTransformer: Value (%@) does not respond to -floatValue.",
			[value class]];
    }
    
// Return the correct control title for the current task mode

	switch (mode) {
	case kTaskIdle:
	default:
		image = [NSImage imageNamed:@"PlayButton.tif"];
		break;
	case kTaskRunning:
		image = [NSImage imageNamed:@"StopButton.tif"];
		break;
	case kTaskStopping:
		image = [NSImage imageNamed:@"StoppingButton.tif"];
		break;
	}
	return image;
}

@end
