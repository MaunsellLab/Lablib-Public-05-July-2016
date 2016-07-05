//
//  VCANStateSystem.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANStateSystem.h"
#import "UtilityFunctions.h"

#import "VCANBlockedState.h"
#import "VCANCueState.h"
#import "VCANEndtrialState.h"
#import "VCANFixGraceState.h"
#import "VCANFixonState.h"
#import "VCANIdleState.h"
#import "VCANIntertrialState.h"
#import "VCANPreCueState.h"
#import "VCANPrestimState.h"
#import "VCANReactState.h"
#import "VCANSaccadeState.h"
#import "VCANStarttrialState.h"
#import "VCANStimulate.h"
#import "VCANStopState.h"
#import "VCANTooFastState.h"

//short				attendLoc;
long 				eotCode;			// End Of Trial code
long 				extendedEotCode;	// End Of Trial code extended
BOOL 				fixated;
LLEyeWindow			*fixWindow;
Quest				*q[kNumStates];
LLEyeWindow			*respWindows[kStimLocs];
float               staircaseContrastPC[kNumStates];
long                staircaseCounts[kNumStates];
VCANStateSystem		*stateSystem;
TrialDesc			trial;
BOOL                isNotTooFast;

@implementation VCANStateSystem

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
        staircaseContrastPC[state] = [[task defaults] floatForKey:VCANStartContrastPCKey];
        [[task defaults] setFloat:staircaseContrastPC[state]
                             forKey:[NSString stringWithFormat:@"VCANStaircaseContrastPC%1ld", state]];
    }
}

- (id)init {

	long index;
	
    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[VCANBlockedState alloc] init] autorelease]];
		[self addState:[[[VCANCueState alloc] init] autorelease]];
		[self addState:[[[VCANEndtrialState alloc] init] autorelease]];
		[self addState:[[[VCANFixonState alloc] init] autorelease]];
		[self addState:[[[VCANFixGraceState alloc] init] autorelease]];
		[self addState:[[[VCANIdleState alloc] init] autorelease]];
		[self addState:[[[VCANIntertrialState alloc] init] autorelease]];
		[self addState:[[[VCANStimulate alloc] init] autorelease]];
		[self addState:[[[VCANPreCueState alloc] init] autorelease]];
		[self addState:[[[VCANPrestimState alloc] init] autorelease]];
		[self addState:[[[VCANReactState alloc] init] autorelease]];
		[self addState:[[[VCANSaccadeState alloc] init] autorelease]];
		[self addState:[[[VCANStarttrialState alloc] init] autorelease]];
		[self addState:[[[VCANStopState alloc] init] autorelease]];
		[self addState:[[[VCANTooFastState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"Idle"] andStopState:[self stateNamed:@"Stop"]];
		[controller setLogging:NO];
		
		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:VCANFixWindowWidthDegKey]];
		for (index = 0; index < kStimLocs; index++) {
			respWindows[index] = [[LLEyeWindow alloc] init];
			[respWindows[index] setWidthAndHeightDeg:[[task defaults] 
						floatForKey:VCANRespWindowWidthDegKey]];
		}

// Initialize the trialBlock that keeps track of trials and blocks

		stimType = -1;
    }
    [controller setLogging:NO];
	for (index = 0; index < kNumStates; index++) {
        staircaseContrastPC[index] = [[task defaults] floatForKey:
                                      [NSString stringWithFormat:@"VCANStaircaseContrastPC%1ld", index]];
		q[index] = (Quest *)malloc(sizeof(Quest));
		NSAssert(q[index] != nil, @"V4CANStateSystem: failed to allocate memory for q");
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
		q_findIntensity([[task defaults] floatForKey:VCANQuestCriterionKey], pQ->function, 1, &pQ->epsilon, pQ->beta,
                        pQ->gamma, pQ->delta, 0);
		pQ->guess[0] = [[task defaults] floatForKey:VCANQuestGuessContrastPCKey];
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
	updateBlockStatus();
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
	
	[eventData getBytes:&tries];
}

@end
