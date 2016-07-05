//
//  SCBlockedState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCBlockedState.h"
#import "SCUtilities.h"

@implementation SCBlockedState

- (void)stateAction {

	[[task dataDoc] putEvent:@"blocked"];
//	schedule(&bNode, (PSCHED)&blockedTones, PRISYS - 1, 400, -1, NULL);
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCAcquireMSKey]];
}

- (NSString *)name {

    return @"SCBlocked";
}

- (LLState *)nextState {

	if (![[task defaults] boolForKey:SCFixateKey] || ![SCUtilities inWindow:fixWindow]) {
		return [[task stateSystem] stateNamed:@"SCFixon"];
    }
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kMyEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil; 
}

@end
