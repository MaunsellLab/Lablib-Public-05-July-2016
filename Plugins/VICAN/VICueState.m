//
//  VICueState.m
//  VICAN
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "VICueState.h"
#import "VIUtilities.h"

@implementation VICueState

- (void)stateAction;
{
	cueMS = [[task defaults] integerForKey:VICueMSKey];
	if (cueMS > 0) {
		[stimuli setCueSpot:YES location:trial.attendLoc];
		expireTime = [LLSystemUtil timeFromNow:cueMS];
		if ([[task defaults] boolForKey:VIDoSoundsKey]) {
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
	if ([[task defaults] boolForKey:VIFixateKey] && ![VIUtilities inWindow:fixWindow]) {
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
