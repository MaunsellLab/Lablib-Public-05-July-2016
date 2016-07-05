//
//  MTCCueState.m
//  MTContrast
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "MTCCueState.h"

@implementation MTCCueState

- (void)stateAction;
{
	cueMS = [[task defaults] integerForKey:MTCCueMSKey];
	if (cueMS > 0) {
		[stimuli setCueSpot:YES location:trial.attendLoc];
		expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:MTCCueMSKey]];
		if ([[task defaults] boolForKey:MTCDoSoundsKey]) {
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
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:MTCFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
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
