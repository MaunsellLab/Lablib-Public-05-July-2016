//
//  LLStateSystem.h
//  Lablib
//
//  Created by John Maunsell on Sat Mar 29 2003.
//  Copyright (c) 2006. All rights reserved.
//

#import "LLState.h"
#import "LLStateSystemController.h"

@interface LLStateSystem : NSObject {

	LLStateSystemController *controller;
	NSMutableDictionary		*states;
}

- (void)addState:(LLState *)state;
- (BOOL)running;
- (void)setStartState:(LLState *)start andStopState:(LLState *)stop;
- (BOOL)startWithCheckIntervalMS:(double)checkMS;
- (LLState *)stateNamed:(NSString *)name;
- (void)stop;

@end
