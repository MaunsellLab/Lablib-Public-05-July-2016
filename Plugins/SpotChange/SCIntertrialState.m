//
//  SCIntertrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCIntertrialState.h"
#import "UtilityFunctions.h"


@implementation SCIntertrialState

- (void)dumpTrial;
{
	NSLog(@"\n catch attendLoc numStim targetIndex distIndex");
	NSLog(@"%d %ld %ld %ld\n", trial.catchTrial, trial.attendLoc, trial.numStim, trial.targetIndex);
}

- (void)stateAction;
{
    [[task dataController] startDevice];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCIntertrialMSKey]];
	eotCode = kMyEOTCorrect;							// default eot code is correct
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

    return @"SCIntertrial";
}

- (LLState *)nextState {

    if ([task mode] == kTaskIdle) {
        eotCode = kMyEOTQuit;
        return [[task stateSystem] stateNamed:@"Endtrial"];;
    }
    else if ([LLSystemUtil timeIsPast:expireTime]) {
        return [[task stateSystem] stateNamed:@"SCStarttrial"];
    }
    return nil;
}

// Decide which trial type to do next

- (BOOL)selectTrial;
{
	long targetIndex, distIndex, maxTargetIndex, maxStimIndex;
	long index, repsDone, repsNeeded;
	long stimulusMS, interstimMS, reactMS;
	long minTargetMS, maxTargetMS;
	BOOL isCatchTrial, valid;
	float minTargetS, maxTargetS, meanTargetS, meanRateHz, lambda;
	float u, targetOnsetS;
	float catchTrialPC, catchTrialMaxPC;
	extern long argRand;
	BlockStatus *pBS = &blockStatus;

// First check that the user hasn't changed any of the entries affecting block size

	updateBlockStatus();
	for (index = repsDone = repsNeeded = 0; index < pBS->changes; index++) {
		repsNeeded += pBS->validReps[index] + pBS->invalidReps[index];
		repsDone += pBS->validRepsDone[index] + pBS->invalidRepsDone[index];
	}
	if (repsDone >= repsNeeded) {
		attendLoc = 1 - attendLoc;
		for (index = 0; index < pBS->changes; index++) {
			pBS->validRepsDone[index] = pBS->invalidRepsDone[index] = 0;
		}
		pBS->instructDone = 0;
		if (++(pBS->sidesDone) >= kLocations) {
			pBS->blocksDone++;
			pBS->sidesDone = 0;
		}
	}

// If we have done all the requested blocks, return now

	if (pBS->blocksDone >= pBS->blockLimit) {
		return NO;
	}

// determin target onset time and whether it is a catch trial

// Pick a stimulus count for the target, using an exponential distribution

	stimulusMS = [[task defaults] integerForKey:SCStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:SCInterstimMSKey];
	minTargetMS = [[task defaults] integerForKey:SCMinTargetMSKey];
	maxTargetMS = [[task defaults] integerForKey:SCMaxTargetMSKey];
	meanTargetS = [[task defaults] integerForKey:SCMeanTargetMSKey] / 1000.0;;
	minTargetS = minTargetMS / 1000.0;
	maxTargetS = maxTargetMS / 1000.0;
	reactMS = [[task defaults] integerForKey:SCRespTimeMSKey]; 
	catchTrialPC = [[task defaults] floatForKey:SCCatchTrialPCKey]; 
	catchTrialMaxPC = [[task defaults] floatForKey:SCCatchTrialMaxPCKey]; 

// Decide which orientation change to do, and whether it will be valid or invalid

	trial.instructTrial = (pBS->instructDone < pBS->instructTrials);
	for (;;) {
		index = rand() % pBS->changes;
		valid = (trial.instructTrial) ? YES : rand() % 2;
		if (valid) {
			if (pBS->validRepsDone[index] < pBS->validReps[index]) {
				break;
			}
		}
		else {
			if (pBS->invalidRepsDone[index] < pBS->invalidReps[index]) {
				break;
			}
		}
	}
	trial.orientationChangeIndex = index;
	trial.validTrial = valid;
	trial.attendLoc = attendLoc;
	trial.correctLoc = (trial.validTrial) ? attendLoc : 1 - attendLoc;

// Decide whether to use uniform or exponential distribution of target times

	meanRateHz = 1000.0 / (stimulusMS + interstimMS);
	maxTargetIndex = maxTargetS * meanRateHz; 		// last position for target
	maxStimIndex = (maxTargetS + reactMS / 1000.0) * meanRateHz + 1;
	isCatchTrial = NO;
	
	switch ([[task defaults] integerForKey:SCStimDistributionKey]) {
	case kUniform:
		targetIndex = round(((minTargetMS + (rand() % (maxTargetMS - minTargetMS +1))) / 1000.0) * meanRateHz);
		distIndex = round(((minTargetMS + (rand() % (maxTargetMS - minTargetMS +1))) / 1000.0) * meanRateHz);
		if (!trial.instructTrial && (rand() % 1000) < (catchTrialPC * 10.0)) {
			isCatchTrial = YES;
		}
		break;
	case kExponential:
	default:

/*
	To minimize the lower occurence of the first target caused by roundoff,
	the exponential pdf is advanced by half the stimulus period (i.e., stimulus duration + interstimulus interval).
	To make the mean target onset time closer to what is specified by the user, the lambda of the exponential
	is scaled by (mean target onset - minimum target onset + half the stimulus period).
*/
		lambda = log(2.0) / (meanTargetS - minTargetS + 0.5 / meanRateHz);	// lambda of exponential distribution
		for (;;) {
			do {
				u = randUnitInterval(&argRand);			// from Press et al. (1992), use when understood
				targetOnsetS = -1.0 * log(1.0 - u) / lambda + (minTargetS - 0.5 / meanRateHz);
														// inverse cdf of the exponential target onset distribution
			} while ((targetOnsetS > (maxTargetS + 0.5 / meanRateHz)) && trial.instructTrial); 
			if (targetOnsetS > (maxTargetS + 0.5 / meanRateHz)) {
				if ((rand() % 1000) < (catchTrialPC / catchTrialMaxPC * 1000.0)) {
					targetIndex = maxTargetIndex;
					isCatchTrial = YES;
					break;
				}
			}
			else {
				targetIndex = round(targetOnsetS * meanRateHz);
				break;
			}
		}
		break;
	}
	trial.catchTrial = isCatchTrial;
	trial.targetIndex = targetIndex;
    
    // Make it (1-SCGabor1AlphaFactor)*100 % easier for the more eccentric Gabor 1 location
    if ((attendLoc == 1 && trial.validTrial) || (attendLoc == 0 && !trial.validTrial)) {
        trial.orientationChangeDeg = pBS->orientationChangeDeg[trial.orientationChangeIndex] * [[task defaults]floatForKey:SCGabor1AlphaFactorKey];
    }
    else {
        trial.orientationChangeDeg = pBS->orientationChangeDeg[trial.orientationChangeIndex];
    }
	trial.numStim = targetIndex + reactMS / 1000.0 * meanRateHz + 1;
	return YES;
}

@end
