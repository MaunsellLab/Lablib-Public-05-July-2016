//
//  VTFixGraceState.m
//  VideoTest
//
//  Created by John Maunsell on 4/4/05.
//  Copyright 2005. All rights reserved.
//

#import "VTFixGraceState.h"


@implementation VTFixGraceState

- (void)stateAction;
{
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTFixGraceMSKey]];
	if ([[task defaults] boolForKey:VTDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name;
{
    return @"FixGrace";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		if ([fixWindow inWindowDeg:[task currentEyeDeg]])  {
			return [[task stateSystem] stateNamed:@"Prestim"];
		}
		else {
			eotCode = kEOTIgnored;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
	}
	else {
		return nil;
    }
}

@end
