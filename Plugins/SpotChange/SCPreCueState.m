//
//  SCPreCueState.m
//  OrientationChange
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "SCPreCueState.h"


@implementation SCPreCueState

- (void)stateAction {

	long preCueMS = [[task defaults] integerForKey:SCPrecueMSKey];
		
	if ([[task defaults] boolForKey:SCFixateKey]) {				// fixation required && fixated
		[[task dataDoc] putEvent:@"fixate"];
		[scheduler schedule:@selector(updateCalibration) toTarget:self withObject:nil
				delayMS:preCueMS * 0.8];
		if ([[task defaults] boolForKey:SCDoSoundsKey]) {
			[[NSSound soundNamed:kFixateSound] play];
		}
	}
	expireTime = [LLSystemUtil timeFromNow:preCueMS];
}

- (NSString *)name {

    return @"SCPrecue";
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
		return stateSystem->cue;
	}
	return nil;
}

- (void)updateCalibration;
{
	if ([fixWindow inWindowDeg:[task currentEyeDeg]]) {
		[[task eyeCalibrator] updateCalibration:[task currentEyeDeg]];
	}
}


@end
