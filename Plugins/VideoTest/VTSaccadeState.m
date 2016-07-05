//
//  VTSaccadeState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTSaccadeState.h"


@implementation VTSaccadeState

- (void)stateAction {

	[[task dataDoc] putEvent:@"saccade"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTSaccadeTimeMSKey]];
}

- (NSString *)name {

    return @"Saccade";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([respWindows[trial.stimulusInterval] inWindowDeg:[task currentEyeDeg]])  {
		eotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([respWindows[1 - trial.stimulusInterval] inWindowDeg:[task currentEyeDeg]])  {
		eotCode = kEOTWrong;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kEOTFailed;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    return nil;
}

@end
