//
//  VIFixGraceState.m
//  VICAN
//
//  Copyright 2006. All rights reserved.
//

#import "VIFixGraceState.h"
#import "VIUtilities.h"

@implementation VIFixGraceState

- (void)stateAction;
{
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VIFixGraceMSKey]];
	if ([[task defaults] boolForKey:VIDoSoundsKey]) {
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
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		if ([VIUtilities inWindow:fixWindow])  {
			return [[task stateSystem] stateNamed:@"Precue"];
		}
		else {
			eotCode = extendedEotCode = kEOTIgnored;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
	}
	else {
		return nil;
    }
}

@end
