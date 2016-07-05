//
//  TUNWaitFixateState.m
//  Tuning
//
//  Created by John Maunsell on 3/11/07.
//  Copyright 2007 All rights reserved.
//

#import "TUNWaitFixateState.h"

@implementation TUNWaitFixateState

- (void)stateAction;
{
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:TUNAcquireMSKey]];
}

- (NSString *)name;
{
    return @"WaitFixate";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([fixWindow inWindowDeg:[task currentEyeDeg]])  {
		return [[task stateSystem] stateNamed:@"FixGrace"];
    }
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	return nil;
}

@end
