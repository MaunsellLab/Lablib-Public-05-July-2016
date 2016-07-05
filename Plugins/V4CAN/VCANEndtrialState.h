//
//  VCANEndtrialState.h
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANStateSystem.h"

@interface VCANEndtrialState : LLState {

	NSTimeInterval	expireTime;
}

- (void)updateTrial:(BOOL)correct;

@end
