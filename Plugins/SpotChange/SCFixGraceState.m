//
//  SCFixGraceState.m
//  SpotChange
//
//  Copyright 2006. All rights reserved.
//

#import "SCFixGraceState.h"
#import "SCUtilities.h"

@implementation SCFixGraceState

- (void)stateAction;
{
	[[task dataDoc] putEvent:@"fixGrace"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCFixGraceMSKey]];
	if ([[task defaults] boolForKey:SCDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name;
{
    return @"SCFixGrace";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		if ([SCUtilities inWindow:fixWindow])  {
			return [[task stateSystem] stateNamed:@"SCFixate"];
		}
		else {
			eotCode = kMyEOTIgnored;
			return [[task stateSystem] stateNamed:@"Endtrial"];;
		}
	}
	else {
		return nil;
    }
}

@end
