//
//  VCANCueState.m
//  V4CAN
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "VCANCueState.h"
#import "VCANUtilities.h"

@implementation VCANCueState

- (void)stateAction;
{
	cueMS = [[task defaults] integerForKey:VCANCueMSKey];
	if (cueMS > 0) {
		[stimuli setCueSpot:YES location:trial.attendLoc];
		expireTime = [LLSystemUtil timeFromNow:cueMS];
		if ([[task defaults] boolForKey:VCANDoSoundsKey]) {
			[[NSSound soundNamed:kFixOnSound] play];
		}
		[[task dataDoc] putEvent:@"cueOn"];
	}
}

- (NSString *)name {

    return @"Cue";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VCANFixateKey] && ![VCANUtilities inWindow:fixWindow]) {
		eotCode = kEOTBroke;
		extendedEotCode = kEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (cueMS <= 0 || [LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"Prestim"];
	}
	else {
		return nil;
    }
}

@end
