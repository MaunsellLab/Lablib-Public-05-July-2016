//
//  SCPrestimState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCPrestimState.h"

@implementation SCPrestimState

- (void)stateAction;
{
	[stimuli setCueSpot:NO location:trial.attendLoc];
	[[task dataDoc] putEvent:@"preStimuli"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCInterstimMSKey]];
}

- (NSString *)name {

    return @"SCPrestim";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return stateSystem->endtrial;
	}
	if ([[task defaults] boolForKey:SCFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return stateSystem->endtrial;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return stateSystem->stimulate;
	}
	return nil;
}

@end
