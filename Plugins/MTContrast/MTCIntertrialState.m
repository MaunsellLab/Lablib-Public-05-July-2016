//
//  MTCIntertrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCIntertrialState.h"
#import "UtilityFunctions.h"

@implementation MTCIntertrialState

- (void)dumpTrial;
{
	NSLog(@"\n catch instruct, attendLoc numStim targetIndex distIndex stimSpeed targetSpeed");
	NSLog(@"%d %d %d   %d %d %d   %.1f %.1f\n", trial.catchTrial, trial.instructTrial, trial.attendLoc,
		trial.numStim, trial.targetIndex, trial.distIndex, trial.stimulusSpeed, trial.targetSpeed);
}

- (void)stateAction;
{
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:MTCIntertrialMSKey]];
	eotCode = kEOTCorrect;							// default eot code is correct
	brokeDuringStim = NO;				// flag for fixation break during stimulus presentation	

	if (![self selectTrial]) {
		[task setMode:kTaskIdle];					// all blocks have been done
		return;
	}
	[[task dataDoc] putEvent:@"blockStatus" withData:(void *)&blockStatus];
//	[self dumpTrial];
	[stimuli makeStimList:&trial];
//	[stimuli dumpStimList];
}

- (NSString *)name {

    return @"Intertrial";
}

- (LLState *)nextState {

    if ([task mode] == kTaskIdle) {
        eotCode = kEOTQuit;
        return [[task stateSystem] stateNamed:@"Endtrial"];
    }
    else if ([LLSystemUtil timeIsPast:expireTime]) {
        return [[task stateSystem] stateNamed:@"StartTrial"];
    }
    return nil;
}

- (BOOL)selectTrial;
{
	long index, maxTargetIndex, maxStimIndex, stimProbTimes10000;
	long stimulusMS, interstimMS, reactMS, rewardMS;
	float maxTargetS, meanTargetS, meanRateHz, lambda;
	
	updateBlockStatus();

	if (blockStatus.blocksDone >= blockStatus.blockLimit) {
		return NO;
	}
	trial.attendLoc = blockStatus.attendLoc;
	trial.instructTrial = blockStatus.instructsDone < [[task defaults] floatForKey:MTCNumInstructTrialsKey];
	trial.stimulusSpeed = [[task defaults] floatForKey:MTCStimulusSpeedDPSKey];
	trial.targetSpeed = [[task defaults] floatForKey:MTCTargetSpeedDPSKey];
	trial.direction0Deg = [[task defaults] floatForKey:MTCDirectionDegKey];
	trial.direction1Deg = trial.direction0Deg - 180.0;
	if (trial.direction1Deg < 0) {
		trial.direction1Deg += 360.0;
	}

// Pick a stimulus count for the target, using an exponential distribution

	stimulusMS = [[task defaults] integerForKey:MTCStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:MTCInterstimMSKey];
	maxTargetS = [[task defaults] integerForKey:MTCMaxTargetMSKey] / 1000.0;
	meanTargetS = [[task defaults] integerForKey:MTCMeanTargetMSKey] / 1000.0;
	reactMS = [[task defaults] integerForKey:MTCRespTimeMSKey]; 
	rewardMS = [[task defaults] integerForKey:MTCRewardMSKey]; 

	lambda = log(2.0) / meanTargetS;	// lambda of exponential distribution
	stimProbTimes10000 = 10000.0 * (1.0 - exp(-lambda * (stimulusMS + interstimMS) / 1000.0)); 
	meanRateHz = 1000.0 / (stimulusMS + interstimMS);
	maxTargetIndex = maxTargetS * meanRateHz; 		// last position for target
	maxStimIndex = (maxTargetS + reactMS / 1000.0) * meanRateHz + 1;

// Pick a count for the target stimulus, earliest possible position is 1 

	for (index = 1; index < maxTargetIndex; index++) {
		if ((rand() % 10000) < stimProbTimes10000) {
			break;
		}
	}
	if (index >= maxTargetIndex && trial.instructTrial) {	// no catch trial on instruct trial
		index = maxTargetIndex - 1;
	}
	trial.catchTrial = (index >= maxTargetIndex);			// is this a catch trial?
	if (trial.catchTrial) {	
		trial.numStim = maxStimIndex;
		trial.targetIndex = maxStimIndex + 1;
	}
	else {
		trial.targetIndex = index;
		trial.numStim = index + reactMS / 1000.0 * meanRateHz + 1;
	}

// Pick a count for the distractor stimulus, earliest possible position is 1

	lambda = log(2.0) / (meanTargetS / [[task defaults] floatForKey:MTCRelDistractorProbKey]);	// lambda of exponential distribution
	stimProbTimes10000 = 10000.0 * (1.0 - exp(-lambda * (stimulusMS + interstimMS) / 1000.0)); 
	for (index = 1; index < maxTargetIndex; index++) {
		if ((rand() % 10000) < stimProbTimes10000) {
			break;
		}
	}
	trial.distIndex = index;
	return YES;
}

@end
