//
//  VTPoststimState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTPoststimState.h"
#import "UtilityFunctions.h"

@implementation VTPoststimState

- (void)stateAction {

	[[task dataDoc] putEvent:@"postStimuli"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTPostintervalMSKey]];
    [[task synthDataSource] setSpikeRateHz:spikeRateFromStimValue(0.0) atTime:[LLSystemUtil getTimeS]];
}

- (NSString *)name {

    return @"Poststim";
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
		return [[task stateSystem] stateNamed:@"TargetsOn"];
	}
	return nil;
}

@end
