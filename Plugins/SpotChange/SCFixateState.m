//
//  SCFixateState.m
//  SpotChange
//
//  SCPreCueState.m
//	Created by John Maunsell on 2/25/06.
//	modified from SCPreCueState.m by Incheol Kang on 12/8/06
//
//  Copyright 2006. All rights reserved.
//

#import "SCFixateState.h"
#import "SCDigitalOut.h"
#import "SCUtilities.h"

@implementation SCFixateState

- (void)stateAction {
	long fixDurBase, fixJitterMS;
	long fixateMS = [[task defaults] integerForKey:SCFixateMSKey];
	long fixJitterPC = [[task defaults] integerForKey:SCFixJitterPCKey];
		
	if ([[task defaults] boolForKey:SCFixateKey]) {				// fixation required && fixated
		[digitalOut outputEvent:kFixateCode withData:kFixateCode];
		[[task dataDoc] putEvent:@"fixate"];
		[scheduler schedule:@selector(updateCalibration) toTarget:self withObject:nil delayMS:fixateMS * 0.8];
		if ([[task defaults] boolForKey:SCDoSoundsKey]) {
			[[NSSound soundNamed:kFixateSound] play];
		}
	}
	
	if (fixJitterPC > 0){
		fixJitterMS = round((fixateMS * fixJitterPC) / 100.0);
		fixDurBase = fixateMS - fixJitterMS;
		fixateMS = fixDurBase + (rand() % (2 * fixJitterMS + 1));
	}
	
	expireTime = [LLSystemUtil timeFromNow:fixateMS];
}

- (NSString *)name {

    return @"SCFixate";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([[task defaults] boolForKey:SCFixateKey] && ![SCUtilities inWindow:fixWindow]) {
		eotCode = kMyEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"SCStimulate"];
	}
	return nil;
}

- (void)updateCalibration;
{
	if ([SCUtilities inWindow:fixWindow]) {
		[[task eyeCalibrator] updateCalibration:[task currentEyeDeg]];
	}
}


@end
