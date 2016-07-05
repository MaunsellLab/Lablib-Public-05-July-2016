//
//  VIIdleState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VIIdleState.h"

@implementation VIIdleState

- (void)stateAction {
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
    [[task dataController] stopDevice];
}

- (NSString *)name {

    return @"Idle";
}

- (LLState *)nextState {

	if ([task mode] == kTaskEnding) {
		return [[task stateSystem] stateNamed:@"Stop"];
    }
	if (![task mode] == kTaskIdle) {
		return [[task stateSystem] stateNamed:@"Intertrial"];
    }
	else {
        return nil;
    }
}

@end
