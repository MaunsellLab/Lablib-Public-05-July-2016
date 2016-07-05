//
//  MTCBlockedState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCBlockedState.h"

@implementation MTCBlockedState

- (void)stateAction {

	[[task dataDoc] putEvent:@"blocked"];
//	schedule(&bNode, (PSCHED)&blockedTones, PRISYS - 1, 400, -1, NULL);
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:MTCAcquireMSKey]];
}

- (NSString *)name {

    return @"Blocked";
}

- (LLState *)nextState {

	if (![[task defaults] boolForKey:MTCFixateKey] || ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
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
