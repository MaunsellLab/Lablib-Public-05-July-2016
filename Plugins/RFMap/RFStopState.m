//
//  RFStopState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFStopState.h"

@implementation RFStopState

- (void)stateAction;
{
	[stimuli stopStimulus];
	while ([stimuli stimulusOn]) {};
}

- (NSString *)name;
{
    return @"Stop";
}

- (LLState *)nextState;
{
	return nil;
}

@end
