//
//  FTStopState.m
//  Fixate Task
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "FTStopState.h"

@implementation FTStopState

- (void)stateAction;
{
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
