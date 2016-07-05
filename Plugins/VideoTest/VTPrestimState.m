//
//  VTPrestimState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTPrestimState.h"

//#define 	kCalibrationDelayMS		150

@implementation VTPrestimState

- (void)stateAction {

	long preIntervalMS = [[task defaults] integerForKey:VTPreintervalMSKey];
	
	if ([[task defaults] boolForKey:VTFixateKey]) {				// fixation required && fixated
		[[task dataDoc] putEvent:@"fixate"];
		[scheduler schedule:@selector(updateCalibration) toTarget:self withObject:nil
				delayMS:preIntervalMS * 0.8];
		if ([[task defaults] boolForKey:VTDoSoundsKey]) {
			[[NSSound soundNamed:kFixateSound] play];
		}
	}
	[[task dataDoc] putEvent:@"preStimuli"];
	expireTime = [LLSystemUtil timeFromNow:preIntervalMS];
}

- (NSString *)name {

    return @"Prestim";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VTFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"IntervalOne"];
	}
	return nil;
}

- (void)updateCalibration {

	if ([fixWindow inWindowDeg:[task currentEyeDeg]]) {
		[[task eyeCalibrator] updateCalibration:[task currentEyeDeg]];
	}
}

@end
