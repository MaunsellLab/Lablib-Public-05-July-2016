//
//  TUNFixGraceState.m
//  Tuning
//
//  Copyright 2006. All rights reserved.
//

#import "TUNFixGraceState.h"


@implementation TUNFixGraceState

- (void)stateAction;
{
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:TUNFixGraceMSKey]];
	if ([[task defaults] boolForKey:TUNDoSoundsKey]) {
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
	if (![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		return [[task stateSystem] stateNamed:@"WaitFixate"];
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
	return nil;
}

@end
