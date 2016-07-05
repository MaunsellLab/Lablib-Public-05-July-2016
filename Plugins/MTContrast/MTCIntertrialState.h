//
//  MTCIntertrialState.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCStateSystem.h"

@interface MTCIntertrialState : LLState {

	NSTimeInterval	expireTime;
}

- (BOOL)selectTrial;

@end
