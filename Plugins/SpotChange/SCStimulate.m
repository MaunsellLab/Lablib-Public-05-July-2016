//
//  SCStimulate.m
//  SpotChange
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCStimulate.h" 
#import "SCUtilities.h"

@implementation SCStimulate

- (void)stateAction;
{
	[stimuli startStimSequence];
}

- (NSString *)name {

    return @"SCStimulate";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([stimuli targetPresented]) {
		return [[task stateSystem] stateNamed:@"SCTooFast"];
	}
	if ([[task defaults] boolForKey:SCFixateKey] && ![SCUtilities inWindow:fixWindow]) {
		eotCode = kMyEOTBroke;
		return [[task stateSystem] stateNamed:@"SCSaccade"];;
	}
	if (![stimuli stimulusOn]) {
		eotCode = kMyEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil;
}


@end
