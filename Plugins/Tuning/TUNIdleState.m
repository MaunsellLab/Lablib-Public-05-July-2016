//
//  TUNIdleState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNIdleState.h"

@implementation TUNIdleState

- (void)stateAction;
{
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
}

- (NSString *)name;
{
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
