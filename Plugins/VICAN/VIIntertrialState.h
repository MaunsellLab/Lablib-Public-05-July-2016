//
//  VIIntertrialState.h
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VIStateSystem.h"

@interface VIIntertrialState : LLState {

	NSTimeInterval	expireTime;
}

- (BOOL)selectTrial;

@end
