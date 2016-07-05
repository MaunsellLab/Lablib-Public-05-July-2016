//
//  TUNPrestimState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNPrestimState.h"

@implementation TUNPrestimState

- (void)stateAction;
{
	long preStimMS = [[task defaults] integerForKey:TUNPreStimMSKey];
	
	[[task dataDoc] putEvent:@"preStimuli"];
	expireTime = [LLSystemUtil timeFromNow:preStimMS];
	if ([[task defaults] boolForKey:TUNFixateKey]) {				// fixation required && fixated
		[[task dataDoc] putEvent:@"fixate"];
		[scheduler schedule:@selector(updateCalibration) toTarget:self withObject:nil
				delayMS:preStimMS * 0.8];
		if ([[task defaults] boolForKey:TUNDoSoundsKey]) {
			[[NSSound soundNamed:kFixateSound] play];
		}
	}
	expireTime = [LLSystemUtil timeFromNow:preStimMS];
}

- (NSString *)name {

    return @"Prestim";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:TUNFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"Stimulate"];
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
