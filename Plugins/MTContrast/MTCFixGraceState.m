//
//  MTCFixGraceState.m
//  MTContrast
//
//  Copyright 2006. All rights reserved.
//

#import "MTCFixGraceState.h"


@implementation MTCFixGraceState

- (void)stateAction;
{
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:MTCFixGraceMSKey]];
	if ([[task defaults] boolForKey:MTCDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name;
{
    return @"Fix Grace";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		if ([fixWindow inWindowDeg:[task currentEyeDeg]])  {
			return [[task stateSystem] stateNamed:@"Precue"];
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
