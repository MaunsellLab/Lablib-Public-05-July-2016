//
//  TUNStateSystem.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNStateSystem.h"
#import "UtilityFunctions.h"

#import "TUNBlockedState.h"
#import "TUNEndtrialState.h"
#import "TUNFixGraceState.h"
#import "TUNFixonState.h"
#import "TUNIdleState.h"
#import "TUNIntertrialState.h"
#import "TUNPrestimState.h"
#import "TUNStarttrialState.h"
#import "TUNStimulate.h"
#import "TUNStopState.h"
#import "TUNWaitFixateState.h"

short				attendLoc;
long 				eotCode;			// End Of Trial code
BOOL 				fixated;
LLEyeWindow			*fixWindow;
TUNStateSystem		*stateSystem;
TrialDesc			trial;

@implementation TUNStateSystem

- (void)dealloc;
 {
    [fixWindow release];
    [super dealloc];
}

- (id)init;
{
    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[TUNBlockedState alloc] init] autorelease]];
		[self addState:[[[TUNEndtrialState alloc] init] autorelease]];
		[self addState:[[[TUNFixonState alloc] init] autorelease]];
		[self addState:[[[TUNFixGraceState alloc] init] autorelease]];
		[self addState:[[[TUNIdleState alloc] init] autorelease]];
		[self addState:[[[TUNIntertrialState alloc] init] autorelease]];
		[self addState:[[[TUNStimulate alloc] init] autorelease]];
		[self addState:[[[TUNPrestimState alloc] init] autorelease]];
		[self addState:[[[TUNStarttrialState alloc] init] autorelease]];
		[self addState:[[[TUNStopState alloc] init] autorelease]];
		[self addState:[[[TUNWaitFixateState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"Idle"] andStopState:[self stateNamed:@"Stop"]];
		[controller setLogging:NO];
		
		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:TUNFixWindowWidthDegKey]];

// Initialize the trialBlock that keeps track of trials and blocks

		stimType = -1;
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

- (void) reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long contrast;
	
	for (contrast = 0; contrast < kMaxSteps; contrast++) {
		stimDone[contrast] = 0;
	}
	blockStatus.blocksDone = 0;
	blockStatus.blockLimit = [[task defaults] integerForKey:TUNBlockLimitKey];
}

- (void) stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	float normalizedValue;
	StimDesc *pSD = (StimDesc *)[eventData bytes];
	

	normalizedValue = pSD->testValue / [[task defaults] floatForKey:TUNMaxValueKey];
 //   [[task synthDataDevice] setSpikeRateHz:spikeRateFromStimValue(normalizedValue) atTime:[LLSystemUtil getTimeS]];
    [[task synthDataDevice] setSpikeRateHz:50.0 atTime:[LLSystemUtil getTimeS]];
}

- (void) stimulusOff:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    [[task synthDataDevice] setSpikeRateHz:spikeRateFromStimValue(0.0) atTime:[LLSystemUtil getTimeS]];
}

- (void) tries:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long tries;
	
	[eventData getBytes:&tries];
}

@end
