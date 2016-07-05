//
//  VIPreCueState.m
//  VICAN
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "VIPreCueState.h"
#import "VIUtilities.h"

@implementation VIPreCueState

- (void)stateAction {

	long preCueMS = [[task defaults] integerForKey:VIPrecueMSKey];
	
	if (preCueMS > 0) {
		preCueMS = preCueMS * 0.5 + (rand() % preCueMS);
	}
	if ([[task defaults] boolForKey:VIFixateKey]) {				// fixation required && fixated
		[[task dataDoc] putEvent:@"fixate"];
		[digitalOut outputEvent:kFixateCode withData:0x0];
		[scheduler schedule:@selector(updateCalibration) toTarget:self withObject:nil delayMS:preCueMS * 0.8];
		if ([[task defaults] boolForKey:VIDoSoundsKey]) {
			[[NSSound soundNamed:kFixateSound] play];
		}
	}
	expireTime = [LLSystemUtil timeFromNow:preCueMS];
}

- (NSString *)name {

    return @"Precue";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VIFixateKey] && ![VIUtilities inWindow:fixWindow]) {
		eotCode = extendedEotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"Cue"];
	}
	return nil;
}

- (void)updateCalibration;
{
    long eyeIndex;
    
    for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
        if ([fixWindow inWindowDeg:([task currentEyesDeg])[eyeIndex]]) {
            [[task eyeCalibrator] updateCalibration:([task currentEyesDeg])[eyeIndex] forEye:eyeIndex];
        }
    }
}


@end
