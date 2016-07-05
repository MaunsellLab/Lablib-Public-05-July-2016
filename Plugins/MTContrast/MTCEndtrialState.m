//
//  MTCEndtrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCEndtrialState.h"
#import "UtilityFunctions.h"

#define kMinRewardMS	10
#define kMinTrials		4

@implementation MTCEndtrialState

- (long)juiceMS;
{
	return [[task defaults] integerForKey:MTCRewardMSKey];
}

- (void)stateAction {

	long trialCertify, longValue;
	
	[stimuli stopAllStimuli];
	[[task dataDoc] putEvent:@"stimulusOff" withData:&longValue];
	
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
		if (trial.instructTrial) {
			blockStatus.instructsDone++;
		}
//		if (trialCertify == nil) {
			[stimuli tallyStimuli];
/*			NSLog(@"StimDone: %d %d", repsDoneAtLoc(0), repsDoneAtLoc(1));
			NSLog(@"stim: %5d%5d%5d%5d%5d%5d%5d%5d",
				stimDone[0][0], stimDone[0][1], stimDone[0][2], stimDone[0][3], 
				stimDone[0][4], stimDone[0][5], stimDone[0][6], stimDone[0][7]);
			NSLog(@"      %5d%5d%5d%5d%5d%5d%5d%5d",
				stimDone[1][0], stimDone[1][1], stimDone[1][2], stimDone[1][3], 
				stimDone[1][4], stimDone[1][5], stimDone[1][6], stimDone[1][7]); */
//		}
		break;
	case kEOTWrong:
		if ([[task defaults] boolForKey:MTCDoSoundsKey]) {
			[[NSSound soundNamed:kNotCorrectSound] play];
		}
		break;
	case kEOTBroke:
		if (brokeDuringStim) {
			expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:MTCBreakPunishMSKey]];
		}
		// Fall through
	default:
		if ([[task defaults] boolForKey:MTCDoSoundsKey]) {
			[[NSSound soundNamed:kNotCorrectSound] play];
		}
		break;
	}	
	[[task dataDoc] putEvent:@"trialCertify" withData:(void *)&trialCertify];
	[[task dataDoc] putEvent:@"trialEnd" withData:(void *)&eotCode];
	[[task synthDataDevice] setSpikeRateHz:spikeRateFromStimValue(0.0) atTime:[LLSystemUtil getTimeS]];
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
		return [[task stateSystem] stateNamed:@"Idle"];
    }
	else if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"Intertrial"];
	}
	else {
		return nil;
	}
}

@end
