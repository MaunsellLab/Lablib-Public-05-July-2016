//
//  VTEndtrialState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTEndtrialState.h"
#import "UtilityFunctions.h"

#define kMinRewardMS	10
#define kMinTrials		4

@implementation VTEndtrialState

- (long)juiceMS;
{
	long juiceMS, interval, stimIndex;
	double fractions[kIntervals];
	
	juiceMS = [[task defaults] integerForKey:VTRewardMSKey];
	stimIndex = trial.stimulusIndex;
	if (MIN(intervalTotals[kFirst][stimIndex], intervalTotals[kSecond][stimIndex]) >= kMinTrials) {
		for (interval = 0; interval < kIntervals; interval++) {
			fractions[interval] = 
				intervalCorrects[interval][stimIndex] / (double)intervalTotals[interval][stimIndex];
		}
		if (trial.stimulusInterval == 0) {
			juiceMS = (1.0 - fractions[kFirst] + fractions[kSecond]) * juiceMS + kMinRewardMS;
		}
		else{
			juiceMS = (1.0 + fractions[kFirst] - fractions[kSecond]) * juiceMS + kMinRewardMS;
		}
	}
	return juiceMS;
}

- (void)stateAction {

	long trialCertify, value;
	
    [stimuli setFixSpot:NO];
    [stimuli setTargets:NO contrast0:0 contrast1:0];
	[stimuli erase];
	[[task dataDoc] putEvent:@"stimulusOff" withData:&trial.stimulusIndex];
	
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
		intervalCorrects[trial.stimulusInterval][trial.stimulusIndex]++;
		intervalTotals[trial.stimulusInterval][trial.stimulusIndex]++;
		[task performSelector:@selector(doJuice:) withObject:self];
		if (trialCertify == 0) {
			[trialBlock countCurrentTrial:YES];
		}
		break;
	case kEOTWrong:
		intervalTotals[trial.stimulusInterval][trial.stimulusIndex]++;
		if (trialCertify == 0) {
			[trialBlock countCurrentTrial:NO];
		}
		if ([[task defaults] boolForKey:VTDoSoundsKey]) {
			[[NSSound soundNamed:kNotCorrectSound] play];
		}
		break;
	case kEOTBroke:
		if (brokeDuringStim) {
			expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTBreakPunishMSKey]];
		}
		// Fall through
	default:
		if ([[task defaults] boolForKey:VTDoSoundsKey]) {
			[[NSSound soundNamed:kNotCorrectSound] play];
		}
		break;
	}
	value = [trialBlock trialsDoneCurrentBlock];
	[[task dataDoc] putEvent:@"blockTrialsDone" withData:(void *)&value];
	value = [trialBlock blocksDone];
	[[task dataDoc] putEvent:@"blocksDone" withData:(void *)&value];
	[[task dataDoc] putEvent:@"trialCertify" withData:(void *)&trialCertify];
	[[task dataDoc] putEvent:@"trialEnd" withData:(void *)&eotCode];
    [[task synthDataSource] setSpikeRateHz:2.5 atTime:[LLSystemUtil getTimeS]];
    [[task synthDataSource] setEyeTargetOff];
    [[task synthDataSource] doLeverUp];
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
		return [[task stateSystem] stateNamed:@"Idle"];
    }
	else if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"Intertrial"];
	}
	else {
		return nil;
	}
}

- (void)reset {
	
	long interval, level;
	
	for (interval = 0; interval < kIntervals; interval++) {
		for (level = 0; level < kMaxLevels; level++) {
			intervalCorrects[interval][level] = intervalTotals[interval][level] = 0.0;
		}
	}
}

@end
