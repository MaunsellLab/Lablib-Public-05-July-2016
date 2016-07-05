//
//  Fixate.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFFixateState.h"

@implementation RFFixateState

- (void)stateAction {

	behaviorMode = kBehaviorFixating;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:RFDoFixateKey]) {				// fixation required && fixated
		[[task dataDoc] putEvent:@"fixate"];
		[scheduler schedule:@selector(updateCalibration) toTarget:self withObject:nil
				delayMS:1000.0];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:RFDoSoundsKey]) {
			[[NSSound soundNamed:kFixateSound] play];
		}
	}
	
	// Randomization needed in here ???
	
	expireTime = [LLSystemUtil timeFromNow:[[NSUserDefaults standardUserDefaults] integerForKey:RFMeanFixateMSKey]];
}

- (NSString *)name {

    return @"Fixate";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:RFDoFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	return nil;
}

- (void)updateCalibration {

	if ([fixWindow inWindowDeg:[task currentEyeDeg]]) {
		[[task eyeCalibrator] updateCalibration:[task currentEyeDeg]];
	}
}

@end
