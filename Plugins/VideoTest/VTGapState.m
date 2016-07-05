//
//  VTGapState.m
//  Experiment
//
//  Created by John Maunsell on Fri Dec 26 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTGapState.h"
#import "UtilityFunctions.h"

@implementation VTGapState

- (void)stateAction {

	[[task dataDoc] putEvent:@"gap"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTGapMSKey]];
    [[task synthDataSource] setSpikeRateHz:spikeRateFromStimValue(0.0) atTime:[LLSystemUtil getTimeS]];
}

- (NSString *)name {

    return @"Gap";
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
		return [[task stateSystem] stateNamed:@"intervalTwo"];
	}
	return nil;
}


@end
