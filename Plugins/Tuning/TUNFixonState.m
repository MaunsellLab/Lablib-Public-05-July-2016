//
//  TUNFixonState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNFixonState.h"

@implementation TUNFixonState

- (void)stateAction;
{
    [stimuli setFixSpot:YES];
    [[task synthDataDevice] doLeverDown];
    [[task synthDataDevice] setEyeTargetOn:NSMakePoint(0, 0)];
	if ([[task defaults] boolForKey:TUNDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name;
{
    return @"Fixon";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[task defaults] boolForKey:TUNFixateKey]) { 
		return [[task stateSystem] stateNamed:@"Prestim"];
    }
	return [[task stateSystem] stateNamed:@"WaitFixate"];
}

@end
