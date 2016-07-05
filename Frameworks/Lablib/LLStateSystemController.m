//
//  LLStateSystem.m
//  Lablib
//
//  Created by John Maunsell on Sat Mar 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLStateSystemController.h"

#define kAutoreleaseIntervalS   10

@implementation LLStateSystemController

- (void)runStateSystem {							// check the state system for a transition

	LLState *pState;
	NSDate *nextRelease, *sleepDate;
    NSAutoreleasePool *threadPool;

    if (startState == nil) {						// no start state defined
        return;
    }
    threadPool = [[NSAutoreleasePool alloc] init];
	nextRelease = [[NSDate dateWithTimeIntervalSinceNow:kAutoreleaseIntervalS] retain];

    currentState = startState;						// set the current state to start state
	for (;;) {
		if (logStates) {
			NSLog(@"Running state \"%@\"", [currentState name]);
		}
        [currentState stateAction];					// run the action function for current state
        if (currentState == stopState) {			// stop the system if this is the stop state
            break;
        }
		for (;;) {
			pState = [currentState nextState];		// get the next state to run
			if (pState != nil) {
                currentState = pState;				// make next state active
                break;
            }
			sleepDate = [[NSDate alloc] initWithTimeIntervalSinceNow:checkPeriodS];
			[NSThread sleepUntilDate:sleepDate];
			[sleepDate release];
            if (stopFlag) {							// command to terminate the system
                break;
            }
			if ([nextRelease timeIntervalSinceNow] < 0.0) {
				[nextRelease release];
				nextRelease = [[NSDate dateWithTimeIntervalSinceNow:kAutoreleaseIntervalS] retain];
				[threadPool release];
				threadPool = [[NSAutoreleasePool alloc] init];
			}
        }
		if (stopFlag) {								// if we were terminated, run stop action function
            [stopState stateAction]; 					// run the stop state action	
            break;
        }
	}
    currentState = nil;								// mark system stopped
	[nextRelease release];
    [threadPool release];
}

- (LLStateSystemController *)initWithStartState:(LLState *)start stopState:(LLState *)stop;
{
	if ([super init]) {
        startState = start;
        stopState = stop;
        currentState = nil;
  	}
   	return self;
}

- (BOOL) running {

    return (currentState != nil);
}

// set the logging on or off

- (void)setLogging:(BOOL)state {

	logStates = state;
}

- (void)setStartState:(LLState *)start stopState:(LLState *)stop;
{
	startState = start;
	stopState = stop;
}

- (LLState *)startState;
{
	return startState;
}

- (BOOL)startWithCheckIntervalMS:(double)checkMS { // start the system running

    checkPeriodS = checkMS / 1000.0;
	if (currentState != nil) {							// don't activate an active system
		return NO;
	}
    else {
        stopFlag = NO;
        [NSThread detachNewThreadSelector:@selector(runStateSystem) toTarget:self withObject:nil];
	}
	return YES;
}

- (void) stop {										// stop the system

    stopFlag = YES;
}

- (LLState *)stopState;
{
	return stopState;
}

@end
