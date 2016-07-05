//
//  VIFixonState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VIFixonState.h"
#import "VIUtilities.h"

@implementation VIFixonState

- (void)stateAction {

    [stimuli setFixSpot:YES];
    [[task synthDataDevice] doLeverDown];
    [[task synthDataDevice] setEyeTargetOn:NSMakePoint(0, 0)];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VIAcquireMSKey]];
	if ([[task defaults] boolForKey:VIDoSoundsKey]) {
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
	if (![[task defaults] boolForKey:VIFixateKey]) { 
		return [[task stateSystem] stateNamed:@"Precue"];
    }
	else if ([VIUtilities inWindow:fixWindow])  {
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
