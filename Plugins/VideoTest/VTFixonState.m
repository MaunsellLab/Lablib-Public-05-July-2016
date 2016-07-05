//
//  VTFixonState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTFixonState.h"

@implementation VTFixonState

- (void)stateAction {

    [stimuli setFixSpot:YES];
    [[task synthDataSource] doLeverDown];
    [[task synthDataSource] setEyeTargetOn:NSMakePoint(0, 0)];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTAcquireMSKey]];
	if ([[task defaults] boolForKey:VTDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name {

    return @"Fixon";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[task defaults] boolForKey:VTFixateKey]) { 
		return [[task stateSystem] stateNamed:@"Prestim"];
    }
	else if ([fixWindow inWindowDeg:[task currentEyeDeg]])  {
		return [[task stateSystem] stateNamed:@"FixGrace"];
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
