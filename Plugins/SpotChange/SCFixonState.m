//
//  SCFixonState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCFixonState.h"
#import "SCDigitalOut.h"
#import "SCUtilities.h"

@implementation SCFixonState

- (void)stateAction {

    [stimuli setFixSpot:YES];
	[[task dataDoc] putEvent:@"fixOn"];
	[digitalOut outputEvent:kFixOnCode withData:kFixOnCode];
    [[task synthDataDevice] setEyeTargetOn:NSMakePoint(0, 0)];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCAcquireMSKey]];
	if ([[task defaults] boolForKey:SCDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name {

    return @"SCFixon";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if (![[task defaults] boolForKey:SCFixateKey]) { 
		return [[task stateSystem] stateNamed:@"SCFixate"];
    }
	else if ([SCUtilities inWindow:fixWindow])  {
		return [[task stateSystem] stateNamed:@"SCFixGrace"];
    }
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kMyEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	else {
		return nil;
    }
}

@end
