//
//  FTStartState.m
//  Fixate Task
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "FTStartState.h"

@implementation FTStartState

- (void)stateAction;
{
}

- (NSString *)name {

    return @"Start";
}

- (LLState *)nextState {

	return [[task stateSystem] stateNamed:@"Idle"];
}

@end
