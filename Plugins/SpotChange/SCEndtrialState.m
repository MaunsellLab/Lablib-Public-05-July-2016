//
//  SCEndtrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCEndtrialState.h"
#import "UtilityFunctions.h"
//MRC 12/10/07
#import "SCDigitalOut.h"

#define kMinRewardMS	10
#define kMinTrials		4

@implementation SCEndtrialState

- (long)juiceMS;
{
	return [[task defaults] integerForKey:SCRewardMSKey];
}

- (void)stateAction {

	long trialCertify, eotLLCode, myEOTCode;
	long longValue = 0;
    static long errorCounter;
	long codeTranslation[kMyEOTTypes] = {kEOTCorrect, kEOTFailed, kEOTWrong, kEOTWrong, kEOTBroke, 
					kEOTIgnored, kEOTQuit};
	
	[stimuli stopAllStimuli];
	[[task dataDoc] putEvent:@"stimulusOff" withData:&longValue];

// Put our trial end code, then tranlate it into something that everyone else will understand.
    
    myEOTCode = eotCode;
	[[task dataDoc] putEvent:@"myTrialEnd" withData:(void *)&eotCode];
	eotCode = codeTranslation[eotCode];
	
// The computer may have failed to create the display correctly.  We check that now
// If the computer failed, the monkey will still get rewarded for correct trial,
// but the trial will be done over.  Other computer checks can be added here.

	trialCertify = 0;
	if (![[stimuli monitor] success]) {
		trialCertify |= (0x1 << kCertifyVideoBit);
	}
	expireTime = [LLSystemUtil timeFromNow:0];					// no delay, except for breaks (below)
	switch (eotCode) {
	case kEOTFailed:
		if (trial.catchTrial == YES) {
			[task performSelector:@selector(doJuice:) withObject:self];
		}
		else {
			if ([[task defaults] boolForKey:SCDoSoundsKey]) {
				[[NSSound soundNamed:kNotCorrectSound] play];
			}
			if (trialCertify == 0L) {
				if (trial.instructTrial) {
					//blockStatus.instructDone++; // enforce correct instruction trials
				}
				else {
					if (trial.validTrial) {
                        blockStatus.validRepsDone[trial.orientationChangeIndex]++;
                    }
                    else {
                        blockStatus.invalidRepsDone[trial.orientationChangeIndex]++;
                    }

				}
			}
		}
		break;
	case kEOTCorrect:
		[task performSelector:@selector(doJuice:) withObject:self];
		if (trialCertify == 0L && !trial.catchTrial) {
			if (trial.instructTrial) {
				blockStatus.instructDone++;
			}
			else {
				if (trial.validTrial) {
					blockStatus.validRepsDone[trial.orientationChangeIndex]++;
				}
				else {
					blockStatus.invalidRepsDone[trial.orientationChangeIndex]++;
				}
			}
            errorCounter = 0;
		}
		break;
//    case kEOTWrong:
//            expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCBreakPunishMSKey]];
//            NSLog(@"added break punishment for early to invalid or valid");
//            if ([[task defaults] boolForKey:SCDoSoundsKey]) {
//                [[NSSound soundNamed:kNotCorrectSound] play];
//            }
//            break;
	case kEOTBroke:
		if (brokeDuringStim) {
			expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCBreakPunishMSKey]];
		}
		// Fall through
    case kEOTWrong:
	default:
		if ([[task defaults] boolForKey:SCDoSoundsKey]) {
			[[NSSound soundNamed:kNotCorrectSound] play];
		}
		break;
	}
    
    // Do punishments for false alarms (time or stimulus)
    
    if (myEOTCode == kMyEOTEarlyToValid) {
        expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCValidFATimePunishMSKey]];
        NSLog(@"Give time out for early valid");
    }
    else if (myEOTCode == kMyEOTEarlyToInvalid) {
        expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:SCInvalidFATimePunishMSKey]];
    }

	
    // Repeat instruction trials if too many misses in a row (ingoring invalids)
    
    if (!trial.instructTrial && trial.validTrial && eotCode == kEOTFailed) {                                                         
		errorCounter++;
	}
    if (errorCounter >= [[task defaults] integerForKey:SCNumMistakesForExtraInstructionsKey]) {
        blockStatus.instructDone = [[task defaults]integerForKey:SCInstructionTrialsKey] -
        [[task defaults]integerForKey:SCNumExtraInstructTrialsKey];
        errorCounter = 0;
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
	eotLLCode = codeTranslation[eotCode];
    [digitalOut outputEvent:kTrialEndCode withData:eotLLCode];
}

- (NSString *)name;
{
    return @"Endtrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		return [[task stateSystem] stateNamed:@"SCIdle"];
    }
	else if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"SCIntertrial"];
	}
	else {
		return nil;
	}
}

@end
