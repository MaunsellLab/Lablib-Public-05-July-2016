//
//  VIStateSystem.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VIStateSystem.h"
#import "VIUtilities.h"
#import "UtilityFunctions.h"

#import "VIBlockedState.h"
#import "VICueState.h"
#import "VIEndtrialState.h"
#import "VIFixGraceState.h"
#import "VIFixonState.h"
#import "VIIdleState.h"
#import "VIIntertrialState.h"
#import "VIPreCueState.h"
#import "VIPrestimState.h"
#import "VIReactState.h"
#import "VISaccadeState.h"
#import "VIStarttrialState.h"
#import "VIStimulate.h"
#import "VIStopState.h"
#import "VITooFastState.h"

//short				attendLoc;
long 				eotCode;			// End Of Trial code
long 				extendedEotCode;	// End Of Trial code extended
BOOL 				fixated;
LLEyeWindow			*fixWindow;
Quest				*q[kNumStates];
LLEyeWindow			*respWindows[kStimLocs];
float               staircaseContrastPC[kNumStates];
long                staircaseCounts[kNumStates];
VIStateSystem		*stateSystem;
TrialDesc			trial;
BOOL                isNotTooFast;

@implementation VIStateSystem

- (void)dealloc;
{
	long index;
	
	if (questOpen) {
		for (index = 0; index < kNumStates; index++) {
			QuestClose(q[index]);
		}
		questOpen = NO;
	}
	[fixWindow release];
	[respWindows[0] release];
	[respWindows[1] release];
	[super dealloc];
}

- (void)doStaircaseReset;
{
    long state;
    
    for (state = 0; state < kNumStates; state++) {
        staircaseContrastPC[state] = [[task defaults] floatForKey:VIStartContrastPCKey];
        [[task defaults] setFloat:staircaseContrastPC[state]
                             forKey:[NSString stringWithFormat:@"VIStaircaseContrastPC%1ld", state]];
    }
}

- (id)init {

	long index;
	
    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[VIBlockedState alloc] init] autorelease]];
		[self addState:[[[VICueState alloc] init] autorelease]];
		[self addState:[[[VIEndtrialState alloc] init] autorelease]];
		[self addState:[[[VIFixonState alloc] init] autorelease]];
		[self addState:[[[VIFixGraceState alloc] init] autorelease]];
		[self addState:[[[VIIdleState alloc] init] autorelease]];
		[self addState:[[[VIIntertrialState alloc] init] autorelease]];
		[self addState:[[[VIStimulate alloc] init] autorelease]];
		[self addState:[[[VIPreCueState alloc] init] autorelease]];
		[self addState:[[[VIPrestimState alloc] init] autorelease]];
		[self addState:[[[VIReactState alloc] init] autorelease]];
		[self addState:[[[VISaccadeState alloc] init] autorelease]];
		[self addState:[[[VIStarttrialState alloc] init] autorelease]];
		[self addState:[[[VIStopState alloc] init] autorelease]];
		[self addState:[[[VITooFastState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"Idle"] andStopState:[self stateNamed:@"Stop"]];
		[controller setLogging:NO];
		
		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:VIFixWindowWidthDegKey]];
		for (index = 0; index < kStimLocs; index++) {
			respWindows[index] = [[LLEyeWindow alloc] init];
			[respWindows[index] setWidthAndHeightDeg:[[task defaults] 
						floatForKey:VIRespWindowWidthDegKey]];
		}

// Initialize the trialBlock that keeps track of trials and blocks

		stimType = -1;
    }
    [controller setLogging:NO];
	for (index = 0; index < kNumStates; index++) {
        staircaseContrastPC[index] = [[task defaults] floatForKey:
                                      [NSString stringWithFormat:@"VIStaircaseContrastPC%1ld", index]];
		q[index] = (Quest *)malloc(sizeof(Quest));
		NSAssert(q[index] != nil, @"VICANStateSystem: failed to allocate memory for q");
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

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long state, stim;
	Quest *pQ;
		
	for (state = 0; state < kNumStates; state++) {
        
        staircaseCounts[state] = 0;     // number consequtive correct on staircase.  
        
		pQ = q[state];
		if (questOpen) {
			QuestClose(pQ);
		}
		time((time_t *)&pQ->seed);		// unpredictable seed for the random number generator
		srand(pQ->seed);
		pQ->nConds = 1;					// number of conditions in this state
		pQ->grain = 0.1;				// grain (smallest step) of the test intensity
		pQ->nLevels = 1000;				// number of possible testing intensities
		pQ->nTrials = 250;				// limit on the number of trials per determination (not used?)
		pQ->initialSD = 25; 			// initial standard deviation of the threshold intensity guess
		pQ->nResponses = 2;				// two possible responses (correct/wrong)
		pQ->quantileOrder = NAN;		// request that it be initialized by QuestOpen()
		pQ->fakeIt = NO;				// real data, not simulations by the quest routines
		pQ->function = WeibullPResponse;	// we're fitting a Weibull function
		pQ->beta = 5.0;					// Parameters for 2AFC psychometric function
		pQ->gamma = 0.5;
		pQ->delta = 0.01;
		pQ->epsilon = NAN;				// Request epsilon to be set automatically
		q_findIntensity([[task defaults] floatForKey:VIQuestCriterionKey], pQ->function, 1, &pQ->epsilon, pQ->beta,
                        pQ->gamma, pQ->delta, 0);
		pQ->guess[0] = [[task defaults] floatForKey:VIQuestGuessContrastPCKey];
		QuestOpen(pQ);
	}
	questOpen = YES;
	
    [stimuli shuffleStimSequence];
	for (state = 0; state < kNumStates; state++) {
		for (stim = 0; stim < kStimPerState; stim++) {
				stimDone[state][stim] = 0;
		}
		blockStatus.doneStates[state] = 0;
	}
	blockStatus.attendState = rand() % kNumStates;
    NSLog(@"Reset: Set attendState to %ld", blockStatus.attendState);
    blockStatus.attendLoc = blockStatus.attendState % (kNumStates / 2);
	blockStatus.instructsDone = 0;
	blockStatus.statesDoneThisBlock = 0;
	blockStatus.blocksDone = 0;
	[VIUtilities updateBlockStatus:&blockStatus];
    [rewardAverage clear];
    [task performSelector:@selector(doRewardAverage:) withObject:@""];
    [task performSelector:@selector(doRewardTrial:) withObject:@""];
}

- (void) stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	StimDesc *pSD = (StimDesc *)[eventData bytes];
    
    [[task synthDataDevice] setSpikeRateHz:spikeRateFromStimDesc(pSD) atTime:[LLSystemUtil getTimeS]];
}

- (void) stimulusOff:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    [[task synthDataDevice] setSpikeRateHz:spikeRateSpontaneous() atTime:[LLSystemUtil getTimeS]];
}

- (void) tries:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long tries;
	
	[eventData getBytes:&tries length:sizeof(long)];
}

@end
