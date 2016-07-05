//
//  VTStopState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTStopState.h"

@implementation VTStopState

- (void)stateAction {

}

- (NSString *)name {

    return @"Stop";
}

- (LLState *)nextState {

	return nil;
}

@end
