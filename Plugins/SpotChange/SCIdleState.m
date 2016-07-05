//
//  SCIdleState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCIdleState.h"

@implementation SCIdleState

- (void)stateAction;
{
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
    [[task dataController] stopDevice];
	blockStatus.instructDone = 0;					// do new instructions trials on restart
}

- (NSString *)name {

    return @"SCIdle";
}

- (LLState *)nextState {

	if ([task mode] == kTaskEnding) {
		return [[task stateSystem] stateNamed:@"SCStop"];
    }
	if (![task mode] == kTaskIdle) {
		return [[task stateSystem] stateNamed:@"SCIntertrial"];
    }
	else {
        return nil;
    }
}

@end
