//
//  FTBlockedState.m
//  Fixate Task
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "FTBlockedState.h"
#import "FTUtilities.h"

@implementation FTBlockedState

- (void)stateAction {

	[[task dataDoc] putEvent:@"blocked"];
//	schedule(&bNode, (PSCHED)&blockedTones, PRISYS - 1, 400, -1, NULL);
	expireTime = [LLSystemUtil timeFromNow:
			[[NSUserDefaults standardUserDefaults] integerForKey:FTAcquireMSKey]];
}

- (NSString *)name {

    return @"Blocked";
}

- (LLState *)nextState {

	if (![[NSUserDefaults standardUserDefaults] boolForKey:FTDoFixateKey] || 
						![FTUtilities inWindow:fixWindow]) {
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
