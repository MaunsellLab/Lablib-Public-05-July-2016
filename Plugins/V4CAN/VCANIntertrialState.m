//
//  VCANIntertrialState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANIntertrialState.h"
#import "UtilityFunctions.h"

@implementation VCANIntertrialState

- (void)dumpTrial;
{
	NSLog(@"\n catch instruct attendLoc numStim targ0 targ1 targ2 reward");
	NSLog(@"%4d %7d %8ld %9ld %5ld %5ld %5ld %6ld\n", trial.catchTrial, trial.instructTrial, trial.attendLoc,
		trial.numStim, trial.targetIndices[0], trial.targetIndices[1], trial.targetIndices[2], trial.rewardMS);
}

- (void)stateAction;
{
//    static int repCounter;
    
    [[task dataController] startDevice];
//    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];       // Remove this for Bram's code

	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VCANIntertrialMSKey]];
    if (trial.repeatCount == 0) {
        if (![self selectTrial]) {
            [task setMode:kTaskIdle];					// all blocks have been done
            return;
        }
        [stimuli makeStimList:&trial];
//        [self dumpTrial];
//        [stimuli dumpStimList];
    }
    [[task dataDoc] putEvent:@"blockStatus" withData:(void *)&blockStatus];
	eotCode = extendedEotCode = kEOTCorrect;		// default eot code is correct
	brokeDuringStim = NO;				// flag for fixation break during stimulus presentation
    isNotTooFast = FALSE; // flag for stimulus present but too fast saccade
}

- (NSString *)name {

    return @"Intertrial";
}

- (LLState *)nextState {

    if ([task mode] == kTaskIdle) {
        eotCode = extendedEotCode = kEOTQuit;
        return [[task stateSystem] stateNamed:@"Endtrial"];
    }
    else if ([LLSystemUtil timeIsPast:expireTime]) {
        return [[task stateSystem] stateNamed:@"StartTrial"];
    }
    return nil;
}

- (BOOL)selectTrial;
{
	long index, stim, maxTargetIndex, stimProbTimes10000, trialDurationMS, maxTargetMS;
	long stimulusMS, interstimMS, reactMS, rewardMinMS, rewardMaxMS;
	float estimate, maxTargetS, meanTargetS, meanRateHz, lambda, minT, maxT, tau;
    NSString *rewardString;
	
	updateBlockStatus();
	maxTargetMS = [[task defaults] integerForKey:VCANMaxTargetMSKey];
	if (blockStatus.blocksDone >= blockStatus.blockLimit) {		// finished all blocks
		return NO;
	}
	trial.attendState = blockStatus.attendState;
	trial.attendLoc = blockStatus.attendLoc;
    trial.repeatCount = 0;                  // we don't normally repeat trials, only for special training
	trial.instructTrial = blockStatus.instructsDone < [[task defaults] floatForKey:VCANNumInstructTrialsKey];
    trial.hasDistractors = FALSE;
	for (stim = 0; stim < kStimLocs; stim++) {
//		estimate = (q[trial.attendState]->qConds[0]->trialsTotal > 0) ? q[trial.attendState]->thresholdEstimate[0] :
//						[[task defaults] floatForKey:VCANQuestGuessContrastPCKey];
//        estimate = MAX([[task defaults] integerForKey:VCANMinContrastChangeKey], estimate);
        estimate = staircaseContrastPC[trial.attendState];
        if (stim != trial.attendLoc) {
            trial.targetContrastChangePC[stim] = MIN(100, [[task defaults] floatForKey:VCANRelDistContrastChangeKey] * MAX([[task defaults] integerForKey:VCANMinContrastChangeKey], estimate));
            
        }
        else {
            trial.targetContrastChangePC[stim] = MIN(100, MAX([[task defaults] integerForKey:VCANMinContrastChangeKey], estimate));
        }
	}
	
// Pick a stimulus count for the target, using an exponential distribution

	stimulusMS = [[task defaults] integerForKey:VCANStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:VCANInterstimMSKey];
	maxTargetS = [[task defaults] integerForKey:VCANMaxTargetMSKey] / 1000.0;
	meanTargetS = [[task defaults] integerForKey:VCANMeanTargetMSKey] / 1000.0;
	reactMS = [[task defaults] integerForKey:VCANRespTimeMSKey]; 
	minT = [[task defaults] floatForKey:VCANStimLeadMSKey];
	maxT = [[task defaults] floatForKey:VCANMaxTargetMSKey];

	lambda = log(2.0) / meanTargetS;	// lambda of exponential distribution
	stimProbTimes10000 = MAX(1, 10000.0 * (1.0 - exp(-lambda * (stimulusMS + interstimMS) / 1000.0)));
	meanRateHz = 1000.0 / (stimulusMS + interstimMS);
	maxTargetIndex = MAX(2, maxTargetS * meanRateHz); 		// last allowed index  for target

// Decide whether this should be a catch trial
    
	if (trial.instructTrial || [[task defaults] boolForKey:VCANTrainingModeKey]) {
        trial.catchTrial = NO;
    }
    else {
        trial.catchTrial = (rand() % 100) < [[task defaults] floatForKey:VCANCatchTrialPCKey];
    }
    
// Pick a count for the target stimulus, earliest possible position is 1 

    if (trial.catchTrial) {
        trial.targetOnTimeMS = maxTargetMS;
		trial.numStim = trial.targetIndices[trial.attendLoc] = maxTargetIndex;
    }
    else {
        index = 0;
        do {
            index = (index % (maxTargetIndex - 1)) + 1;
        } while ((rand() % 10000) >= stimProbTimes10000 || index < 1);
		trial.targetIndices[trial.attendLoc] = index;
		trial.numStim = index + reactMS / 1000.0 * meanRateHz + 1;
        trial.targetOnTimeMS = index * 1000.0 / meanRateHz;
    }
    NSLog(@"trial.targetOnTimeMS %ld", trial.targetOnTimeMS);
  
//// Pick a single distractor location and set the remaining distractor location to the maximum index, earliest position is 1
//    
//    
//    long distractorLoc;
//    BOOL foundDistractorLoc = FALSE;
//    while (!foundDistractorLoc) {
//        distractorLoc = rand() % kStimLocs;
//        
//        if (distractorLoc !=  trial.attendLoc) {
//            lambda = log(2.0) / ([[task defaults] floatForKey:VCANMeanDistractorMSKey] / 1000.0);
//            stimProbTimes10000 = 10000.0 * (1.0 - exp(-lambda * (stimulusMS + interstimMS) / 1000.0));
//            for (index = 1; index < maxTargetIndex; index++) {
//                if ((rand() % 10000) < stimProbTimes10000) {
//                    break;
//                }
//            }
//            trial.targetIndices[distractorLoc] = index;
//            foundDistractorLoc = TRUE;
//        }
//    }
//    for (stim = 0; stim < kStimLocs; stim++) {
//        if (stim != trial.attendLoc && stim != distractorLoc){
//            trial.targetIndices[stim] = maxTargetIndex;
//        }
//    }
//
        
	
// Pick a count for the distractor stimulus, earliest possible position is 1

	lambda = log(2.0) / ([[task defaults] floatForKey:VCANMeanDistractorMSKey] / 1000.0);
	for (stim = 0; stim < kStimLocs; stim++) {
		if (stim == trial.attendLoc) {
			continue;
		}
		stimProbTimes10000 = 10000.0 * (1.0 - exp(-lambda * (stimulusMS + interstimMS) / 1000.0));
		for (index = 1; index < maxTargetIndex; index++) {
			if ((rand() % 10000) < stimProbTimes10000) {
				break;
			}
		}
		trial.targetIndices[stim] = index;
        
    }

    
// if any distractor is presented before or with the target then also a distractor near the attended location
    
    if (trial.attendLoc < 2){
        index = (trial.attendLoc+1) % 2 ; //NearRF distractor location index
    }
    else {
        index = (trial.attendLoc+1) % 2 + 2;
    }
    
    if (trial.targetIndices[index] > trial.targetIndices[trial.attendLoc]) {
        for (stim = 0; stim < kStimLocs; stim++) {
            if (stim != trial.attendLoc && stim != index) {
                if (trial.targetIndices[stim] < trial.targetIndices[trial.attendLoc]) {                    
                    trial.targetIndices[index] = trial.targetIndices[stim];
                    trial.hasDistractors = TRUE;
//                    NSLog(@"adding a near-attended-location distractor at position %li because position %li has one", index, stim);
                    break;
                }
            }
        }
    }
    else {
        trial.hasDistractors = TRUE;
    }

	trial.rewardMS = [[task defaults] integerForKey:VCANRewardMSKey];
	if ([[task defaults] boolForKey:VCANDoVarRewardsKey] && (minT < maxT)) {
		rewardMinMS = [[task defaults] floatForKey:VCANVarRewardMinMSKey];
		rewardMaxMS = [[task defaults] floatForKey:VCANVarRewardMaxMSKey];
		tau = [[task defaults] floatForKey:VCANVarRewardTCMSKey];
		trialDurationMS = MIN(maxT, trial.numStim * 1000.0 / meanRateHz);
        trial.rewardMS = rewardMinMS + (rewardMaxMS - rewardMinMS) * exp(-(maxT - trialDurationMS) / tau);
        
        // Give extra reward for difficult positions:
        if (trial.attendState < 2 || trial.attendState == 4 || trial.attendState == 5) {
            trial.rewardMS = trial.rewardMS * [[task defaults]floatForKey:VCANExtraRewardRightFactorKey];
        }
        
        if ([rewardAverage n] == 0) {
            rewardString = @"";
        }
        else {
            rewardString = [NSString stringWithFormat:@"Avg reward %.0f ms (n = %.0f)", [rewardAverage mean], [rewardAverage n]];
        }
        [task performSelector:@selector(doRewardAverage:) withObject:rewardString];
        [task performSelector:@selector(doRewardTrial:)
                   withObject:[NSString stringWithFormat:@"Reward this trial %ld ms", trial.rewardMS]];
	}
		
	return YES;
}

@end
