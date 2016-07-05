//
//  SCStateSystem.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCStateSystem.h"
#import "UtilityFunctions.h"

#import "SCBlockedState.h"
#import "SCEndtrialState.h"
#import "SCFixGraceState.h"
#import "SCFixonState.h"
#import "SCIdleState.h"
#import "SCIntertrialState.h"
#import "SCFixateState.h"
#import "SCReactState.h"
#import "SCSaccadeState.h"
#import "SCStarttrialState.h"
#import "SCStimulate.h"
#import "SCStopState.h"
#import "SCTooFastState.h"
//MRC 12/10/07
#import "SCDigitalOut.h"

long 				eotCode;			// End Of Trial code
BOOL 				fixated;
LLEyeWindow			*fixWindow;
LLEyeWindow			*respWindow;
SCStateSystem		*stateSystem;
TrialDesc			trial;
LLEyeWindow			*wrongWindow;

@implementation SCStateSystem

- (void)dealloc {

    [fixWindow release];
	[respWindow release];
	[wrongWindow release];
    [super dealloc];
}

- (id)init;
{
    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[SCBlockedState alloc] init] autorelease]];
		[self addState:[[[SCEndtrialState alloc] init] autorelease]];
		[self addState:[[[SCFixonState alloc] init] autorelease]];
		[self addState:[[[SCFixGraceState alloc] init] autorelease]];
		[self addState:[[[SCIdleState alloc] init] autorelease]];
		[self addState:[[[SCIntertrialState alloc] init] autorelease]];
		[self addState:[[[SCStimulate alloc] init] autorelease]];
		[self addState:[[[SCFixateState alloc] init] autorelease]];
		[self addState:[[[SCTooFastState alloc] init] autorelease]];
		[self addState:[[[SCReactState alloc] init] autorelease]];
		[self addState:[[[SCSaccadeState alloc] init] autorelease]];
		[self addState:[[[SCStarttrialState alloc] init] autorelease]];
		[self addState:[[[SCStopState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"SCIdle"] andStopState:[self stateNamed:@"SCStop"]];

		[controller setLogging:NO];
	
		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:SCFixWindowWidthDegKey]];
			
		respWindow = [[LLEyeWindow alloc] init];
		[respWindow setWidthAndHeightDeg:[[task defaults] floatForKey:SCRespWindowWidthDegKey]];
		wrongWindow = [[LLEyeWindow alloc] init];
		[wrongWindow setWidthAndHeightDeg:[[task defaults] floatForKey:SCRespWindowWidthDegKey]];
        attendLoc = rand() % 2;
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

// Make a block status object that contains the number of blocks to do and how many 
// trials of each type have been done (initialized to zero).

- (void) reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long index;
	
	attendLoc = rand() % 2;
	updateBlockStatus();
	blockStatus.blocksDone = blockStatus.sidesDone = blockStatus.instructDone = 0;
	for (index = 0; index < blockStatus.changes; index++) {
		blockStatus.validRepsDone[index] = blockStatus.invalidRepsDone[index] = 0;
	}
}

- (void) stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	float normalizedValue, baselineValue;
	StimDesc *pSD = (StimDesc *)[eventData bytes];
	
	baselineValue = 0.1;
	normalizedValue = pSD->orientationChangeDeg / [[task defaults] floatForKey:SCMaxDirChangeDegKey];
	normalizedValue = (normalizedValue + baselineValue) / (1.0 + baselineValue);
    [[task synthDataDevice] setSpikeRateHz:spikeRateFromStimValue(normalizedValue) atTime:[LLSystemUtil getTimeS]];
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
