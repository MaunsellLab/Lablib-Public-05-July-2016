//
//  VTStateSystem.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTStateSystem.h"
#import "UtilityFunctions.h"

#import "VTBlockedState.h"
#import "VTEndtrialState.h"
#import "VTFixGraceState.h"
#import "VTFixonState.h"
#import "VTGapState.h"
#import "VTIdleState.h"
#import "VTIntertrialState.h"
#import "VTPoststimState.h"
#import "VTPrestimState.h"
#import "VTReactState.h"
#import "VTSaccadeState.h"
#import "VTStartState.h"
#import "VTStarttrialState.h"
#import "VTIntervalOneState.h"
#import "VTStopState.h"
#import "VTTargetsOnState.h"

long 					eotCode;			// End Of Trial code
BOOL 					fixated;
LLEyeWindow				*fixWindow;
BOOL					hadLeverDown;
BOOL					leverIsDown;
LLEyeWindow				*respWindows[kIntervals];
VTStateSystem			*stateSystem;
TrialDesc				trial;

@implementation VTStateSystem

- (void)dealloc;
{    
    [fixWindow release];
	[respWindows[kFirst] release];
	[respWindows[kSecond] release];
	[trialBlock release];
    [super dealloc];
}

- (id)init {

	long interval;
	
    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[VTBlockedState alloc] init] autorelease]];
		[self addState:[[[VTEndtrialState alloc] init] autorelease]];
		[self addState:[[[VTFixonState alloc] init] autorelease]];
		[self addState:[[[VTFixGraceState alloc] init] autorelease]];
		[self addState:[[[VTGapState alloc] init] autorelease]];
		[self addState:[[[VTIdleState alloc] init] autorelease]];
		[self addState:[[[VTIntertrialState alloc] init] autorelease]];
		[self addState:[[[VTIntervalOneState alloc] init] autorelease]];
		[self addState:[[[VTPoststimState alloc] init] autorelease]];
		[self addState:[[[VTPrestimState alloc] init] autorelease]];
		[self addState:[[[VTReactState alloc] init] autorelease]];
		[self addState:[[[VTSaccadeState alloc] init] autorelease]];
		[self addState:[[[VTStartState alloc] init] autorelease]];
		[self addState:[[[VTStarttrialState alloc] init] autorelease]];
		[self addState:[[[VTStopState alloc] init] autorelease]];
		[self addState:[[[VTTargetsOnState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"Start"] andStopState:[self stateNamed:@"Stop"]];
		[controller setLogging:NO];

		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:VTFixWindowWidthDegKey]];
		for (interval = kFirst; interval < kIntervals; interval++) {
			respWindows[interval] = [[LLEyeWindow alloc] init];
			[respWindows[interval] setWidthAndHeightDeg:[[task defaults] 
						floatForKey:VTRespWindowWidthDegKey]];
		}

// Initialize the trialBlock that keeps track of trials and blocks

		trialBlock = [[LLTrialBlock alloc] 
				initWithTrialCount:[[task defaults] integerForKey:VTContrastsKey]
				triesCount:[[task defaults] integerForKey:VTTriesKey]
				blockCount:[[task defaults] integerForKey:VTBlockLimitKey]];
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

// Respond to a change in the number of blocks

- (void) blockLimit:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long limit;
	
	[eventData getBytes:&limit];
	[trialBlock setBlocks:limit];
}

- (void) contrastStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	StimParams stimParams;
	
	if (stimType >= 0 && stimType == kVisualStimulus) {
		[eventData getBytes:&stimParams];
        [trialBlock setTrialCount:stimParams.levels];
		[trialBlock reset];
	}
}

- (void) currentStimParams:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	StimParams stimParams;
	
	if (stimType >= 0 && stimType == kElectricalStimulus) {
		[eventData getBytes:&stimParams];
        [trialBlock setTrialCount:stimParams.levels];
		[trialBlock reset];
	}
}

// When the stimulus type changes, we need to change the number of trials per block
// and reset the counters.

- (void) stimulusType:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long newStimType;
	StimParams *pStimParams;
	
	[eventData getBytes:&newStimType];
    if (stimType != newStimType) {
        stimType = newStimType;
		pStimParams = getStimParams(stimType);
        [trialBlock setTrialCount:pStimParams->levels];
		[trialBlock reset];
	}
}

- (void) reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[trialBlock reset];
	
// The indirect way of calling reset in the end trial state is used to avoid a circularity
// in header files refrences.

	[[[task stateSystem] stateNamed:@"Endtrial"] performSelector:@selector(reset)];
}

- (void) tries:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long tries;
	
	[eventData getBytes:&tries];
	[trialBlock setTriesCount:tries];
}

@end
