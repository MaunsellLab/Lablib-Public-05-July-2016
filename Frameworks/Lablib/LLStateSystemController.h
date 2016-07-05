//
//  LLStateSystemController.h
//  Lablib
//
//  Created by John Maunsell on Sat Mar 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLState.h"

@interface LLStateSystemController : NSObject {

	double		checkPeriodS;						// period for checking transitions
	LLState 	*startState;						// pointer to start state
	LLState 	*stopState;							// pointer to stop state
	LLState 	*currentState;						// pointer to current state
	BOOL		logStates;							// flag to log every state transition
	BOOL		stopFlag;							// flag to stop system
}

- (LLStateSystemController *)initWithStartState:(LLState 	*)start stopState:(LLState 	*)stop;
- (BOOL) running;									// report whether the system is running
- (void)setLogging:(BOOL)state;						// set the logging on or off
- (void)setStartState:(LLState *)start stopState:(LLState *)stop;
- (LLState *)startState;
- (BOOL) startWithCheckIntervalMS:(double)checkMS;	// start the system running
- (void) stop;										// stop the system
- (LLState *)stopState;

@end
