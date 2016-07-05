//
//  VTStartState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTStartState.h"
#import "UtilityFunctions.h"

@implementation VTStartState

- (void)stateAction {

	long lValue = 0;
	
	announceEvents();
    [[task dataDoc] putEvent:@"reset" withData:&lValue];
}

- (NSString *)name {

    return @"Start";
}

- (LLState *)nextState {

	return [[task stateSystem] stateNamed:@"Idle"];
}

@end
