//
//  VTIdleState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTIdleState.h"

@implementation VTIdleState

- (void)stateAction {

	[[task dataController] setDataEnabled:NO];
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
