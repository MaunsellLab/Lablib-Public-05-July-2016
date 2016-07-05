//
//  VIIntertrialState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VIIntertrialState.h"
#import "VIUtilities.h"

@implementation VIIntertrialState

- (void)dumpTrial;
{
	NSLog(@"\n catch instruct attendLoc numStim targ0 targ1 targ2 reward");
	NSLog(@"%4d %7d %8ld %9ld %5ld %6ld\n", trial.catchTrial, trial.instructTrial, trial.attendLoc,
		trial.numStim, trial.targetIndex, trial.rewardMS);
}

- (void)stateAction;
{
//    static int repCounter;
    
    [[task dataController] startDevice];
//    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];       // Remove this for Bram's code

	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VIIntertrialMSKey]];
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
	long index, maxTargetIndex, stimProbTimes10000, trialDurationMS, maxTargetMS, numValids, numNearInvalids, numFarInvalids, totNumStim, validAlphaRand, counter;
	long stimulusMS, interstimMS, reactMS, rewardMinMS, rewardMaxMS;
	float maxTargetS, meanTargetS, meanRateHz, lambda, minT, maxT, tau;
    NSString *rewardString;
    NSMutableArray *changeArray;
    NSDictionary *changeEntry;
	
	[VIUtilities updateBlockStatus:&blockStatus];
	maxTargetMS = [[task defaults] integerForKey:VIMaxTargetMSKey];
	if (blockStatus.blocksDone >= blockStatus.blockLimit) {		// finished all blocks
		return NO;
	}
	trial.attendState = blockStatus.attendState;
	trial.attendLoc = blockStatus.attendLoc;
    trial.repeatCount = 0;                  // we don't normally repeat trials, only for special training
	trial.instructTrial = blockStatus.instructsDone < [[task defaults] floatForKey:VINumInstructTrialsKey];
    
   
    // Get the total number of valid and invalid presentations:
    
    changeArray = [NSMutableArray arrayWithArray:[[task defaults] arrayForKey:VIAlphaChangeArrayKey]];
    numValids = numNearInvalids = numFarInvalids = 0;
    for (index = 0; index < blockStatus.numChanges; index++) {
        changeEntry = [changeArray objectAtIndex:index];
        numValids += [[changeEntry objectForKey:VIValidRepsKey] integerValue];
        numNearInvalids += [[changeEntry objectForKey:VIInvalidNearRepsKey] integerValue];
        numFarInvalids += [[changeEntry objectForKey:VIInvalidFarRepsKey] integerValue];
    }
    totNumStim = numValids + numNearInvalids + numFarInvalids;
    
    // Pick a random trialType:
    
    validAlphaRand = (rand() % totNumStim) + 1;
    NSLog(@"validAlphaRand = %li", validAlphaRand);
    if (validAlphaRand <= numValids || trial.instructTrial) {
        trial.trialType = kTargetAttendLoc;
        trial.targetPos = trial.attendLoc;
        counter = 0;
    }
    else if (validAlphaRand > numValids && validAlphaRand <= numValids + numNearInvalids) {
        trial.trialType = kTargetNear;
        trial.targetPos = trial.attendLoc + 1 - 2 * (trial.attendLoc % 2);
        counter = numValids;
    }
    else {
        trial.trialType = kTargetFar;
        trial.targetPos = 2 * (1 - trial.attendLoc / 2) + (rand() % 2);
        counter = numValids + numNearInvalids;
    }
    
    // and the associated random alpha level:
    
    for (index = 0; index < blockStatus.numChanges; index++) {
        changeEntry = [changeArray objectAtIndex:index];
        switch (trial.trialType) {
            case kTargetAttendLoc:
                counter += [[changeEntry objectForKey:VIValidRepsKey] integerValue];
                break;
            case kTargetNear:
                counter += [[changeEntry objectForKey:VIInvalidNearRepsKey] integerValue];
                break;
            case kTargetFar:
                counter += [[changeEntry objectForKey:VIInvalidFarRepsKey] integerValue];
                break;
        }
        if (counter >= validAlphaRand) {
            trial.targetAlphaChangeIndex = index;
            trial.targetAlphaChange = [[changeEntry objectForKey:VIChangeKey] floatValue];
            break;
        }
    }
    
    // Tintin performs better at the lower left positions so we change the alpha by a user-defined factor:
    
    if (trial.targetPos == 2) {
        trial.targetAlphaChange = trial.targetAlphaChange * [[task defaults] floatForKey:VILoc2AlphaFactorKey];
    }
    else if (trial.targetPos == 3) {
        trial.targetAlphaChange = trial.targetAlphaChange * [[task defaults] floatForKey:VILoc3AlphaFactorKey];
    }
    
	
// Pick a stimulus count for the target, using an exponential distribution

	stimulusMS = [[task defaults] integerForKey:VIStimDurationMSKey];
	interstimMS = [[task defaults] integerForKey:VIInterstimMSKey];
	maxTargetS = [[task defaults] integerForKey:VIMaxTargetMSKey] / 1000.0;
	meanTargetS = [[task defaults] integerForKey:VIMeanTargetMSKey] / 1000.0;
	reactMS = [[task defaults] integerForKey:VIRespTimeMSKey]; 
	minT = [[task defaults] floatForKey:VIStimLeadMSKey];
	maxT = [[task defaults] floatForKey:VIMaxTargetMSKey];

	lambda = log(2.0) / meanTargetS;	// lambda of exponential distribution
	stimProbTimes10000 = MAX(1, 10000.0 * (1.0 - exp(-lambda * (stimulusMS + interstimMS) / 1000.0)));
	meanRateHz = 1000.0 / (stimulusMS + interstimMS);
	maxTargetIndex = MAX(2, maxTargetS * meanRateHz); 		// last allowed index  for target

// Decide whether this should be a catch trial
    
	if (trial.instructTrial || [[task defaults] boolForKey:VITrainingModeKey]) {
        trial.catchTrial = NO;
    }
    else {
        trial.catchTrial = (rand() % 100) < [[task defaults] floatForKey:VICatchTrialPCKey];
    }
    
// Pick a count for the target stimulus, earliest possible position is 1 

    if (trial.catchTrial) {
        trial.targetOnTimeMS = maxTargetMS;
		trial.numStim = trial.targetIndex = maxTargetIndex;
        trial.trialType = kTargetAttendLoc;

    }
    else {
        index = 0;
        do {
            index = (index % (maxTargetIndex - 1)) + 1;
        } while ((rand() % 10000) >= stimProbTimes10000 || index < 1);
		trial.targetIndex = index;
		trial.numStim = index + reactMS / 1000.0 * meanRateHz + 1;
        trial.targetOnTimeMS = index * 1000.0 / meanRateHz;
    }
    NSLog(@"trial.targetOnTimeMS %ld", trial.targetOnTimeMS);
  
	trial.rewardMS = [[task defaults] integerForKey:VIRewardMSKey];
	if ([[task defaults] boolForKey:VIDoVarRewardsKey] && (minT < maxT)) {
		rewardMinMS = [[task defaults] floatForKey:VIVarRewardMinMSKey];
		rewardMaxMS = [[task defaults] floatForKey:VIVarRewardMaxMSKey];
		tau = [[task defaults] floatForKey:VIVarRewardTCMSKey];
		trialDurationMS = MIN(maxT, trial.numStim * 1000.0 / meanRateHz);
        trial.rewardMS = rewardMinMS + (rewardMaxMS - rewardMinMS) * exp(-(maxT - trialDurationMS) / tau);
        
        // Give less reward for invalids:
        
        if (trial.trialType != kTargetAttendLoc) {
            trial.rewardMS = trial.rewardMS * [[task defaults]floatForKey:VIDistractorRewardFactorKey];
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
