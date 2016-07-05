//
//  VIEndtrialState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VIEndtrialState.h"
#import "VIUtilities.h"
#import "UtilityFunctions.h"

#define kMinRewardMS	10
#define kMinTrials		4

BOOL distrTrial;

@implementation VIEndtrialState

- (long)juiceMS;
{
	return trial.rewardMS;
}

- (void)stateAction;
{
	long trialCertify;
    LLDataDevice *ITC18DataDevice;
    LLIntervalMonitor *monitor;
    static long errorCounter;
    
	[stimuli stopAllStimuli];
	
// The computer may have failed to create the display correctly.  We check that now
// If the computer failed, the monkey will still get rewarded for correct trial,
// but the trial will be done over.  Other computer checks can be added here.

	trialCertify = 0;
	if (![[stimuli monitor] success]) {
		trialCertify |= (0x1 << kCertifyVideoBit);
	}
    if ((ITC18DataDevice = [[task dataController] deviceWithName:@"ITC-18"]) != nil) {
        monitor = [(LLITC18DataDevice *)ITC18DataDevice monitor];
        if (![monitor success]) {
            trialCertify |= (0x1 << kCertifyDataBit);
            [LLSystemUtil runAlertPanelWithMessageText:@"ITC Certify Failure" informativeText:@""];
//            [NSAlert alertWithMessageText:@"ITC Certify Failure" defaultButton:@"OK"
//                          alternateButton:nil otherButton:nil informativeTextWithFormat:nil];
        }
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
			if (trialCertify == 0 && trial.repeatCount == 0 && trial.trialType == kTargetAttendLoc && !trial.catchTrial) {
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
		expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VIBreakPunishMSKey]];
        if ([[task defaults] boolForKey: VIDoErrorCueKey]) {
            [stimuli setCueAfterError];
        }
	}
    
    // Repeat the exact same trial if the animal got it wrong (only for valids; for training only)
    
    if (resetFlag) {
        trial.repeatCount = 0;
    }
    else if (!trial.catchTrial && trial.trialType == 0 && eotCode != kEOTCorrect) {
        trial.repeatCount = [[task defaults]integerForKey:VINumRepsAfterIncorrectKey];
    }

    // Repeat instruction trials if too many errors in a row (ingoring invalids)
    
    if (!trial.instructTrial && trial.trialType == 0 && (extendedEotCode == kEOTFailed
                                            || extendedEotCode == kEOTWrong)) {
		errorCounter++;
	}
    if (errorCounter >= [[task defaults] integerForKey:VINumMistakesForExtraInstructionsKey]) {
        blockStatus.instructsDone = [[task defaults]integerForKey:VINumInstructTrialsKey] -
                                                        [[task defaults]integerForKey:VINumExtraInstructTrialsKey];
        errorCounter = 0;
    }
    
        
	if (eotCode != kEOTCorrect && [[task defaults] boolForKey:VIDoSoundsKey]) {
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
		[VIUtilities reset];
        resetFlag = NO;
	}
    if ([task mode] == kTaskStopping || [task mode] == kTaskEnding) {	 // Requested to stop or quit
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
    BOOL trainingMode = [[task defaults] boolForKey:VITrainingModeKey];
//	QuestResults qResults;
	
	if (!trial.catchTrial && !trial.instructTrial) {
        
        if (!trainingMode || trainingMode) {
            
            if (correct) {
                if (++staircaseCounts[state] >= [[task defaults] integerForKey:VINumCorrectStaircaseUpKey]) { // must be 3 for ~83% correct
                    staircaseCounts[state] = 0;
                    //staircaseContrastPC[state] -= [[task defaults] floatForKey:VIStepDownPCKey];
                    staircaseContrastPC[state] += [[task defaults] floatForKey:VIStepDownPCKey]; // This is just for TRAINING, remove
                    staircaseContrastPC[state] = MAX(staircaseContrastPC[state],
                                                     [[task defaults] floatForKey:VIMinContrastChangeKey]);
                }
            }
            else {
                staircaseCounts[state] = 0;
                //            staircaseContrastPC[state] += exp((4.0 / 3.0) *
                //                                            log((double)[[task defaults] floatForKey:VIStepDownPCKey]));
                staircaseContrastPC[state] -= exp((4.0 / 3.0) *
                                                  log((double)[[task defaults] floatForKey:VIStepDownPCKey])); // This is just for TRAINING, remove
            }
            [[task dataDoc] putEvent:@"staircaseResult" withData:(void *)&staircaseContrastPC[state]];
            [[task defaults] setFloat:staircaseContrastPC[state]
                               forKey:[NSString stringWithFormat:@"VIStaircaseContrastPC%1ld", state]];
            //        NSLog(@"State %ld: (%@) Contrast set to %.1f", trial.attendState, (correct ? @"Correct" : @"Wrong"),
            //              staircaseContrastPC[state]);
            
            
            //        QuestUpdate(q[state], 0, trial.targetAlphaChange[trial.attendLoc], correct);
            //		q[state]->thresholdEstimate[0] = QuestMean(q[state], 0);
            //		qResults.trials = q[state]->qConds[0]->trialsTotal;
            //		qResults.threshold = q[state]->thresholdEstimate[0];
            //		qResults.confidenceInterval = q_error(q[state]->qConds[0]);
            //		[[task dataDoc] putEvent:@"questResults" withData:(void *)&qResults];
            //		NSLog(@"Tested %.2f(%@); threshold %.2f +/- %.2f (n = %ld)", trial.targetAlphaChange[state],
            //			  ((correct) ? @"Correct" : @"Wrong"), qResults.threshold, qResults.confidenceInterval, qResults.trials);
        }
	}
}

@end
