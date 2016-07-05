//
//  VCANStimulate.m
//  V4CAN
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANStimulate.h" 
#import "VCANUtilities.h"

@implementation VCANStimulate

- (void)stateAction;
{
	[stimuli startStimList];
}

- (NSString *)name {

    return @"Stimulate";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VCANFixateKey] &&  ![VCANUtilities inWindow:fixWindow]) {
		return [[task stateSystem] stateNamed:@"Saccade"];	// false alarm, see where he goes to
	}
	if (![stimuli stimulusOn]) {					// catch trial
		eotCode = extendedEotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([stimuli targetPresented]) {				// target had been presented
		return [[task stateSystem] stateNamed:@"TooFast"];
	}
    return nil;
}


@end
