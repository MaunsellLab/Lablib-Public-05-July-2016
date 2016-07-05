//
//  VCANIntertrialState.h
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANStateSystem.h"

@interface VCANIntertrialState : LLState {

	NSTimeInterval	expireTime;
}

- (BOOL)selectTrial;

@end
