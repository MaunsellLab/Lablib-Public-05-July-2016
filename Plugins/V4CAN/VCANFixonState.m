//
//  VCANFixonState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANFixonState.h"
#import "VCANUtilities.h"

@implementation VCANFixonState

- (void)stateAction {

    [stimuli setFixSpot:YES];
    [[task synthDataDevice] doLeverDown];
    [[task synthDataDevice] setEyeTargetOn:NSMakePoint(0, 0)];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VCANAcquireMSKey]];
	if ([[task defaults] boolForKey:VCANDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name {

    return @"Fixon";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
        eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[task defaults] boolForKey:VCANFixateKey]) { 
		return [[task stateSystem] stateNamed:@"Precue"];
    }
	else if ([VCANUtilities inWindow:fixWindow])  {
		return [[task stateSystem] stateNamed:@"Fix Grace"];
    }
	if ([LLSystemUtil timeIsPast:expireTime]) {
        eotCode = extendedEotCode = kEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	else {
		return nil;
    }
}

@end
