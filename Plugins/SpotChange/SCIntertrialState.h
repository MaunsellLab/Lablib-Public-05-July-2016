//
//  SCIntertrialState.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCStateSystem.h"

@interface SCIntertrialState : LLState {

	NSTimeInterval	expireTime;
}

- (BOOL)selectTrial;

@end
