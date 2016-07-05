//
//  TUNEndtrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNEndtrialState.h"
#import "UtilityFunctions.h"

#define kMinRewardMS	10
#define kMinTrials		4

@implementation TUNEndtrialState

- (long)juiceMS;
{
	return [[task defaults] integerForKey:TUNRewardMSKey];
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
//		if (trialCertify == nil) {
			[stimuli tallyStimuli];
/*			NSLog(@"stim: %5d%5d%5d%5d%5d%5d%5d%5d",
				stimDone[0], stimDone[1], stimDone[2], stimDone[3], 
				stimDone[4], stimDone[5], stimDone[6], stimDone[7]);
			NSLog(@"stim: %5d%5d%5d%5d%5d%5d%5d%5d",
				stimDone[8], stimDone[9], stimDone[10], stimDone[11], 
				stimDone[12], stimDone[13], stimDone[14], stimDone[15]); */
//		}
		break;
	case kEOTWrong:
		if ([[task defaults] boolForKey:TUNDoSoundsKey]) {
			[[NSSound soundNamed:kNotCorrectSound] play];
		}
		break;
	case kEOTBroke:
	default:
		if ([[task defaults] boolForKey:TUNDoSoundsKey]) {
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
