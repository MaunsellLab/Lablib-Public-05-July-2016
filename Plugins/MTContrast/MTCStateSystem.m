//
//  MTCStateSystem.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCStateSystem.h"
#import "UtilityFunctions.h"

#import "MTCBlockedState.h"
#import "MTCCueState.h"
#import "MTCEndtrialState.h"
#import "MTCFixGraceState.h"
#import "MTCFixonState.h"
#import "MTCIdleState.h"
#import "MTCIntertrialState.h"
#import "MTCPreCueState.h"
#import "MTCPrestimState.h"
#import "MTCReactState.h"
#import "MTCSaccadeState.h"
#import "MTCStarttrialState.h"
#import "MTCStimulate.h"
#import "MTCStopState.h"

short				attendLoc;
long 				eotCode;			// End Of Trial code
BOOL 				fixated;
LLEyeWindow			*fixWindow;
LLEyeWindow			*respWindows[kLocations];
MTCStateSystem		*stateSystem;
TrialDesc			trial;

@implementation MTCStateSystem

- (void)dealloc;
 {
    [fixWindow release];
	[respWindows[0] release];
	[respWindows[1] release];
    [super dealloc];
}

- (id)init {

	long index;
	
    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[MTCBlockedState alloc] init] autorelease]];
		[self addState:[[[MTCCueState alloc] init] autorelease]];
		[self addState:[[[MTCEndtrialState alloc] init] autorelease]];
		[self addState:[[[MTCFixonState alloc] init] autorelease]];
		[self addState:[[[MTCFixGraceState alloc] init] autorelease]];
		[self addState:[[[MTCIdleState alloc] init] autorelease]];
		[self addState:[[[MTCIntertrialState alloc] init] autorelease]];
		[self addState:[[[MTCStimulate alloc] init] autorelease]];
		[self addState:[[[MTCPreCueState alloc] init] autorelease]];
		[self addState:[[[MTCPrestimState alloc] init] autorelease]];
		[self addState:[[[MTCReactState alloc] init] autorelease]];
		[self addState:[[[MTCSaccadeState alloc] init] autorelease]];
		[self addState:[[[MTCStarttrialState alloc] init] autorelease]];
		[self addState:[[[MTCStopState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"Idle"] andStopState:[self stateNamed:@"Stop"]];
		[controller setLogging:NO];
		
		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:MTCFixWindowWidthDegKey]];
		for (index = 0; index < kLocations; index++) {
			respWindows[index] = [[LLEyeWindow alloc] init];
			[respWindows[index] setWidthAndHeightDeg:[[task defaults] 
						floatForKey:MTCRespWindowWidthDegKey]];
		}

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

- (void)contrastStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	StimParams stimParams;
	
	if (stimType >= 0) {
		[eventData getBytes:&stimParams];
	}
}

- (void) reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long loc, contrast;
	
	for (loc = 0; loc < kLocations; loc++) {
		for (contrast = 0; contrast < kMaxContrasts; contrast++) {
			stimDone[loc][contrast] = 0;
		}
	}
	blockStatus.attendLoc = 0;
	blockStatus.instructsDone = 0;
	blockStatus.locsDoneThisBlock = 0;
	blockStatus.blocksDone = 0;
	updateBlockStatus();
}

- (void) stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	float normalizedValue;
	StimDesc *pSD = (StimDesc *)[eventData bytes];
	
	normalizedValue = pSD->contrastPC / [[task defaults] floatForKey:MTCMaxContrastKey];
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
