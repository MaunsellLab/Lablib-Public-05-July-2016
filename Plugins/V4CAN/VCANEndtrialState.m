//
//  VCANEndtrialState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANEndtrialState.h"
#import "UtilityFunctions.h"

#define kMinRewardMS	10
#define kMinTrials		4

BOOL distrTrial;

@implementation VCANEndtrialState

- (long)juiceMS;
{
	return trial.rewardMS;
}

- (void)stateAction {

	long trialCertify, loc;
    static long errorCounter, numDistrTrials, numCorrectDistrTrials, numNonDistrTrials, numCorrectNonDistrTrials;
    static long numCorrectDistrTrialsPerState[kNumStates], numDistrTrialsPerState[kNumStates];
    static long numCorrectNonDistrTrialsPerState[kNumStates], numNonDistrTrialsPerState[kNumStates];
    
	[stimuli stopAllStimuli];
	
// The computer may have failed to create the display correctly.  We check that now
// If the computer failed, the monkey will still get rewarded for correct trial,
// but the trial will be done over.  Other computer checks can be added here.

	trialCertify = 0;
	if (![[stimuli monitor] success]) {
		trialCertify |= (0x1 << kCertifyVideoBit);
	}
	expireTime = [LLSystemUtil timeFromNow:0];					// no delay, except for breaks (below)
    switch (eotCode) {
		case kEOTCorrect:
			[task performSelector:@selector(doJuice:) withObject:self];
            [rewardAverage addValue:[self juiceMS]];            // keep a record of earned rewards
            errorCounter = 0;
			if (trial.instructTrial) {
				blockStatus.instructsDone++;
			}
            trial.repeatCount = MAX(0, trial.repeatCount -1 );
			if (trialCertify == 0 && trial.repeatCount == 0) {
                [stimuli tallyStimuli];                         // ??? Tally on catch trials
			}
			[self updateTrial:YES];
			break;
		case kEOTFailed:
			[self updateTrial:NO];
			break;
        case kEOTWrong: // this case is just for training remove later; kEOTWrong includes wrongs and earlies
			[self updateTrial:NO];
			break;
 		case kEOTBroke:
		default:
			break;
	}
    
   	if (extendedEotCode == kEOTEarly || extendedEotCode == kEOTWrong || extendedEotCode == kEOTDistractor) {
		expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VCANBreakPunishMSKey]];
        if ([[task defaults] boolForKey: VCANDoErrorCueKey]) {
            [stimuli setCueAfterError];
        }
	}
    
    // Repeat the exact same trial if the animal got it wrong (for training only)
    
    if (resetFlag) {
        trial.repeatCount = 0;
    }
    else if (!trial.catchTrial && eotCode != kEOTCorrect) {
        trial.repeatCount = [[task defaults]integerForKey:VCANNumRepsAfterIncorrectKey];
    }

    // Repeat instruction trials if too many errors in a row
    
    if (!trial.instructTrial && (extendedEotCode == kEOTFailed
                                            || extendedEotCode == kEOTWrong || extendedEotCode == kEOTDistractor)) {
		errorCounter++;
	}
    if (errorCounter >= [[task defaults] integerForKey:VCANNumMistakesForExtraInstructionsKey]) {
        blockStatus.instructsDone = [[task defaults]integerForKey:VCANNumInstructTrialsKey] -
                                                        [[task defaults]integerForKey:VCANNumExtraInstructTrialsKey];
        errorCounter = 0;
    }
    
    // Get percentage of correctly performed (non-)distractor trials
    
    distrTrial = NO;
    if (!trial.instructTrial && extendedEotCode != kEOTBroke && extendedEotCode != kEOTIgnored) {
        for (loc = 0; loc < kStimLocs; loc++) {
            if (loc != trial.attendLoc && trial.targetIndices[loc] <= trial.targetIndices[trial.attendLoc]) {
                numDistrTrials++;
                numDistrTrialsPerState[trial.attendState]++;
                if (extendedEotCode == kEOTCorrect) {
                    numCorrectDistrTrials++;
                    numCorrectDistrTrialsPerState[trial.attendState]++;
                    NSLog(@"Proportion correct distractor trials = %f",(float)numCorrectDistrTrials/numDistrTrials);
                    if (numNonDistrTrialsPerState[trial.attendState] > 0) {
                        NSLog(@"Proportion correct non-distractor trials = %f",(float)numCorrectNonDistrTrials/numNonDistrTrials);
                        NSLog(@"Proportion of distractor trials: %f",(float)numDistrTrials/(numDistrTrials + numNonDistrTrials));
                        
                        NSLog(@"Proportion correct distractor trials for state %li is = %f",trial.attendState,(float)numCorrectDistrTrialsPerState[trial.attendState]/numDistrTrialsPerState[trial.attendState]);
                        NSLog(@"Proportion correct non-distractor trials for state %li is = %f",trial.attendState,(float)numCorrectNonDistrTrialsPerState[trial.attendState]/numNonDistrTrialsPerState[trial.attendState]);
                        NSLog(@"Number of distractor trials for state %li is = %li",trial.attendState, numDistrTrialsPerState[trial.attendState]);
                    }
                }
                distrTrial = YES;
                break;
            }
        }
        if (!distrTrial) {
            numNonDistrTrials++;
            numNonDistrTrialsPerState[trial.attendState]++;
            if (extendedEotCode == kEOTCorrect) {
                numCorrectNonDistrTrials++;
                numCorrectNonDistrTrialsPerState[trial.attendState]++;
            }
        }
    }
    
	if (eotCode != kEOTCorrect && [[task defaults] boolForKey:VCANDoSoundsKey]) {
		[[NSSound soundNamed:kNotCorrectSound] play];
	}
	[[task dataDoc] putEvent:@"trialCertify" withData:(void *)&trialCertify];
	[[task dataDoc] putEvent:@"extendedEOT" withData:(void *)&extendedEotCode];
	[[task dataDoc] putEvent:@"trialEnd" withData:(void *)&eotCode];
	[digitalOut outputEvent:kTrialEndCode withData:0x0];
	[[task synthDataDevice] setSpikeRateHz:spikeRateSpontaneous() atTime:[LLSystemUtil getTimeS]];
    [[task synthDataDevice] setEyeTargetOff];
    [[task synthDataDevice] doLeverUp];
	if (resetFlag) {
		reset();
        resetFlag = NO;
	}
    if ([task mode] == kTaskStopping) {						// Requested to stop
        [task setMode:kTaskIdle];
	}
}

- (NSString *)name;
{
    return @"Endtrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
        [stimuli erase];
		return [[task stateSystem] stateNamed:@"Idle"];
    }
	else if ([LLSystemUtil timeIsPast:expireTime]) {
        [stimuli erase];
		return [[task stateSystem] stateNamed:@"Intertrial"];
	}
	else {
		return nil;
	}
}

- (void)updateTrial:(BOOL)correct;
{
	long state = trial.attendState;
    BOOL trainingMode = [[task defaults] boolForKey:VCANTrainingModeKey];
//	QuestResults qResults;
	
	if (!trial.catchTrial && !trial.instructTrial) {
        
        if ((!trainingMode && trial.hasDistractors) || trainingMode) {
            
            if (correct) {
                if (++staircaseCounts[state] >= [[task defaults] integerForKey:VCANNumCorrectStaircaseUpKey]) { // must be 3 for ~83% correct
                    staircaseCounts[state] = 0;
                    //staircaseContrastPC[state] -= [[task defaults] floatForKey:VCANStepDownPCKey];
                    staircaseContrastPC[state] += [[task defaults] floatForKey:VCANStepDownPCKey]; // This is just for TRAINING, remove
                    staircaseContrastPC[state] = MAX(staircaseContrastPC[state],
                                                     [[task defaults] floatForKey:VCANMinContrastChangeKey]);
                }
            }
            else {
                staircaseCounts[state] = 0;
                //            staircaseContrastPC[state] += exp((4.0 / 3.0) *
                //                                            log((double)[[task defaults] floatForKey:VCANStepDownPCKey]));
                staircaseContrastPC[state] -= exp((4.0 / 3.0) *
                                                  log((double)[[task defaults] floatForKey:VCANStepDownPCKey])); // This is just for TRAINING, remove
            }
            [[task dataDoc] putEvent:@"staircaseResult" withData:(void *)&staircaseContrastPC[state]];
            [[task defaults] setFloat:staircaseContrastPC[state]
                               forKey:[NSString stringWithFormat:@"VCANStaircaseContrastPC%1ld", state]];
            //        NSLog(@"State %ld: (%@) Contrast set to %.1f", trial.attendState, (correct ? @"Correct" : @"Wrong"),
            //              staircaseContrastPC[state]);
            
            
            //        QuestUpdate(q[state], 0, trial.targetContrastChangePC[trial.attendLoc], correct);
            //		q[state]->thresholdEstimate[0] = QuestMean(q[state], 0);
            //		qResults.trials = q[state]->qConds[0]->trialsTotal;
            //		qResults.threshold = q[state]->thresholdEstimate[0];
            //		qResults.confidenceInterval = q_error(q[state]->qConds[0]);
            //		[[task dataDoc] putEvent:@"questResults" withData:(void *)&qResults];
            //		NSLog(@"Tested %.2f(%@); threshold %.2f +/- %.2f (n = %ld)", trial.targetContrastChangePC[state],
            //			  ((correct) ? @"Correct" : @"Wrong"), qResults.threshold, qResults.confidenceInterval, qResults.trials);
        }
	}
}

@end
