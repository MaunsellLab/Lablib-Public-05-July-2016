//
//  FTIdleState.m
//  Fixate Task
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "FTIdleState.h"

@implementation FTIdleState

- (void)stateAction {

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
}

- (NSString *)name {

    return @"Idle";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskEnding) {
		return [[task stateSystem] stateNamed:@"Stop"];
    }
	if ([task mode] != kTaskIdle) {
		return [[task stateSystem] stateNamed:@"Intertrial"];
    }
	else {
        return nil;
    }
}

@end
