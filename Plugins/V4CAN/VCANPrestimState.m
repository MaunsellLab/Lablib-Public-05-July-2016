//
//  VCANPrestimState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANPrestimState.h"
#import "VCANUtilities.h"

@implementation VCANPrestimState

- (void)stateAction;
{
	[stimuli setCueSpot:NO location:trial.attendLoc];
	[[task dataDoc] putEvent:@"preStimuli"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VCANPreStimMSKey]];
}

- (NSString *)name {

    return @"Prestim";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VCANFixateKey] && ![VCANUtilities inWindow:fixWindow]) {
		eotCode = kEOTBroke;
		extendedEotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"Stimulate"];
	}
	return nil;
}

@end
