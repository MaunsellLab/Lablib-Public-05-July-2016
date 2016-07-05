//
//  RFStartState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFStartState.h"
#import "RFMapUtilityFunctions.h"

@implementation RFStartState

- (void)stateAction {

	long lValue = 0;
	
	putParameterEvents();
    [[task dataDoc] putEvent:@"reset" withData:&lValue];
	[stimuli startStimulus];
}

- (NSString *)name {

    return @"Start";
}

- (LLState *)nextState {

	return [[task stateSystem] stateNamed:@"Idle"];
}

@end
