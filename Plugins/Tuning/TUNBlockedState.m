//
//  TUNBlockedState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNBlockedState.h"

@implementation TUNBlockedState

- (void)stateAction {

	[[task dataDoc] putEvent:@"blocked"];
//	schedule(&bNode, (PSCHED)&blockedTones, PRISYS - 1, 400, -1, NULL);
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:TUNAcquireMSKey]];
}

- (NSString *)name {

    return @"Blocked";
}

- (LLState *)nextState {

	if (![[task defaults] boolForKey:TUNFixateKey] || ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		return [[task stateSystem] stateNamed:@"Fixon"];
    }
	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    return nil; 
}

@end
