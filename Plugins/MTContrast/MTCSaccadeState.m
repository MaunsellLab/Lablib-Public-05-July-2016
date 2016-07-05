//
//  MTCSaccadeState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCSaccadeState.h"


@implementation MTCSaccadeState

- (void)stateAction {

	[[task dataDoc] putEvent:@"saccade"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:MTCSaccadeTimeMSKey]];
}

- (NSString *)name {

    return @"Saccade";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([respWindows[trial.attendLoc] inWindowDeg:[task currentEyeDeg]])  {
		eotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([respWindows[1 - trial.attendLoc] inWindowDeg:[task currentEyeDeg]])  {
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
