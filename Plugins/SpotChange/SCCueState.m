//
//  SCCueState.m
//  OrientationChange
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "SCCueState.h"

@implementation SCCueState

- (void)stateAction;
{
	cueMS = [[task defaults] integerForKey:SCCueMSKey];
	if (cueMS > 0) {
		[stimuli setCueSpot:YES location:trial.attendLoc];
		expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCCueMSKey]];
		if ([[task defaults] boolForKey:SCDoSoundsKey]) {
			[[NSSound soundNamed:kFixOnSound] play];
		}
		[[task dataDoc] putEvent:@"cueOn"];
	}
}

- (NSString *)name {

    return @"SCCue";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return stateSystem->endtrial;
	}
	if ([[task defaults] boolForKey:SCFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return stateSystem->endtrial;
	}
	if (cueMS <= 0 || [LLSystemUtil timeIsPast:expireTime]) {
		return stateSystem->prestim;
	}
	else {
		return nil;
    }
}

@end
