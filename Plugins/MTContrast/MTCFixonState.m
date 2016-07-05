//
//  MTCFixonState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCFixonState.h"

@implementation MTCFixonState

- (void)stateAction {

    [stimuli setFixSpot:YES];
    [[task synthDataDevice] doLeverDown];
    [[task synthDataDevice] setEyeTargetOn:NSMakePoint(0, 0)];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:MTCAcquireMSKey]];
	if ([[task defaults] boolForKey:MTCDoSoundsKey]) {
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
	if (![[task defaults] boolForKey:MTCFixateKey]) { 
		return [[task stateSystem] stateNamed:@"Precue"];
    }
	else if ([fixWindow inWindowDeg:[task currentEyeDeg]])  {
		return [[task stateSystem] stateNamed:@"Fix Grace"];
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
