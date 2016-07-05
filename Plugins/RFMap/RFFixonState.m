//
//  RFFixonState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFFixonState.h"

@implementation RFFixonState

- (void)stateAction;
{
    [[stimuli fixSpot] setState:YES];
    [[task synthDataDevice] setEyeTargetOn:NSMakePoint(0, 0)];
	expireTime = [LLSystemUtil timeFromNow:[[NSUserDefaults standardUserDefaults] 
											integerForKey:RFAcquireMSKey]];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:RFDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name;
{
    return @"Fixon";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[NSUserDefaults standardUserDefaults] boolForKey:RFDoFixateKey] || 
							[fixWindow inWindowDeg:[task currentEyeDeg]])  {
		return [[task stateSystem] stateNamed:@"Fixate"];
    }
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	else {
		return nil;
    }
}

@end
