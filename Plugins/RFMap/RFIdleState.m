//
//  RFIdleState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFIdleState.h"

@implementation RFIdleState

- (void)stateAction {

	behaviorMode = kBehaviorAlways;
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
}

- (NSString *)name {

    return @"Idle";
}

- (LLState *)nextState {

	if ([task mode] == kTaskEnding) {
		return [[task stateSystem] stateNamed:@"stop"];
    }
	if ([task mode] == kTaskRunning) {
		return [[task stateSystem] stateNamed:@"Intertrial"];
    }
	else {
        return nil;
    }
}

@end
