//
//  VCANBlockedState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANBlockedState.h"
#import "VCANUtilities.h"

@implementation VCANBlockedState

- (void)stateAction {

	[[task dataDoc] putEvent:@"blocked"];
//	schedule(&bNode, (PSCHED)&blockedTones, PRISYS - 1, 400, -1, NULL);
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VCANAcquireMSKey]];
}

- (NSString *)name {

    return @"Blocked";
}

- (LLState *)nextState;
{
	if (![[task defaults] boolForKey:VCANFixateKey] || ![VCANUtilities inWindow:fixWindow]) {
		return [[task stateSystem] stateNamed:@"Fixon"];
    }
	if ([task mode] == kTaskIdle) {
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = extendedEotCode = kEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    return nil; 
}

@end
