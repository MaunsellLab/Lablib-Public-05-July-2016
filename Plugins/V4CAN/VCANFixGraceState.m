//
//  VCANFixGraceState.m
//  V4CAN
//
//  Copyright 2006. All rights reserved.
//

#import "VCANFixGraceState.h"
#import "VCANUtilities.h"

@implementation VCANFixGraceState

- (void)stateAction;
{
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VCANFixGraceMSKey]];
	if ([[task defaults] boolForKey:VCANDoSoundsKey]) {
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
		if ([VCANUtilities inWindow:fixWindow])  {
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
