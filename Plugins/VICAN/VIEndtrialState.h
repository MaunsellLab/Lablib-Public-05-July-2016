//
//  VIEndtrialState.h
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VIStateSystem.h"

@interface VIEndtrialState : LLState {

	NSTimeInterval	expireTime;
}

- (void)updateTrial:(BOOL)correct;

@end
