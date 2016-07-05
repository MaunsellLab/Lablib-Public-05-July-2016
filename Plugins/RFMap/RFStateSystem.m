//
//  RFStateSystem.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFStateSystem.h"
#import "RFMapUtilityFunctions.h"

#import "RFBlockedState.h"
#import "RFEndtrialState.h"
#import "RFFixonState.h"
#import "RFIdleState.h"
#import "RFIntertrialState.h"
#import "RFFixateState.h"
#import "RFStartState.h"
#import "RFStarttrialState.h"
#import "RFStopState.h"

long 					eotCode;			// End Of Trial code
BOOL 					fixated;
LLEyeWindow				*fixWindow;
BOOL					hadLeverDown;
BOOL					leverIsDown;
RFStateSystem			*stateSystem;
TrialDesc				trial;

@implementation RFStateSystem

- (void)dealloc;
{
    [fixWindow release];
    [super dealloc];
}

- (id)init {

    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[RFBlockedState alloc] init] autorelease]];
		[self addState:[[[RFEndtrialState alloc] init] autorelease]];
		[self addState:[[[RFFixonState alloc] init] autorelease]];
		[self addState:[[[RFIdleState alloc] init] autorelease]];
		[self addState:[[[RFIntertrialState alloc] init] autorelease]];
		[self addState:[[[RFFixateState alloc] init] autorelease]];
		[self addState:[[[RFStartState alloc] init] autorelease]];
		[self addState:[[[RFStarttrialState alloc] init] autorelease]];
		[self addState:[[[RFStopState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"Start"] andStopState:[self stateNamed:@"Stop"]];	
		[controller setLogging:NO];
		
		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:RFFixWindowWidthDegKey]];
    }
    return self;
}

- (BOOL) running {

    return [controller running];
}

- (BOOL) startWithCheckIntervalMS:(double)checkMS {			// start the system running

    return [controller startWithCheckIntervalMS:checkMS];
}

- (void) stop {										// stop the system

    [controller stop];
}

// Methods related to data events follow:

// When the stimulus type changes, we need to change the number of trials per block
// and reset the counters.

- (void) stimulusType:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long stimType;
	static long lastStimType = -1;
	
    [eventData getBytes:&stimType length:sizeof(long)];
//    [eventData getBytes:&stimType];
    if (stimType != lastStimType) {
        lastStimType = stimType;
	}
}

@end
