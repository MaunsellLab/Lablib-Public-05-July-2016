//
//  RFEndtrialState.m
//  RFMap
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFEndtrialState.h"
#import "RFMapUtilityFunctions.h"
//#import "AppController.h"

#define kMinRewardMS	10
#define kMinTrials		4

@implementation RFEndtrialState

- (void)doJuiceOff;
{
	[[task dataController] digitalOutputBitsOn:kRewardBit];
}


- (long)juiceMS {
	
	long juiceMS;
	
	juiceMS = [[task defaults] integerForKey:RFRewardMSKey];
	return juiceMS;
}

- (void)stateAction {

	long trialCertify;
	NSSound *juiceSound;
	
	behaviorMode = kBehaviorRunning;
    [[stimuli fixSpot] setState:NO];
	
// The computer may have failed to create the display correctly.  We check that now
// If the computer failed, the monkey will still get rewarded for correct trial,
// but the trial will be done over.  Other computer checks can be added here.

	trialCertify = 0;
    [stimuli stopStimulus];
    while ([stimuli stimulusOn]) {};
	if (![[stimuli monitor] success]) {
		trialCertify |= (0x1 << kCertifyVideoBit);
	}
    [stimuli startStimulus];
	switch (eotCode) {
	case kEOTCorrect:
		[[task dataController] digitalOutputBitsOff:kRewardBit];
		[scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:nil 
			delayMS:[[task defaults] integerForKey:RFRewardMSKey]];
		if ([[task defaults] boolForKey:RFDoSoundsKey]) {
			juiceSound = [NSSound soundNamed:kCorrectSound];
			if ([juiceSound isPlaying]) {   // won't play again if it's still playing
				[juiceSound stop];
			}
			[juiceSound play];			// play juice sound
		}
		break;
	case kEOTWrong:
		if (trialCertify == 0) {
		}
		//  FALL THROUGH
	default:
		if ([[task defaults] boolForKey:RFDoSoundsKey]) {
			[[NSSound soundNamed:kNotCorrectSound] play];
		}
		break;
	}
	[[task dataDoc] putEvent:@"trialCertify" withData:(void *)&trialCertify];
	[[task dataDoc] putEvent:@"trialEnd" withData:(void *)&eotCode];

	[[task synthDataDevice] setSpikeRateHz:2.5 atTime:[LLSystemUtil getTimeS]];
    [[task synthDataDevice] setEyeTargetOff];
    [[task synthDataDevice] doLeverUp];
	if (resetFlag) {
		reset();
        resetFlag = NO;
	}
//	if (dataFileOpen) {
//		writeToDisk();		
//	}
    if ([task mode] == kTaskStopping) {						// Requested to stop
        [task setMode:kTaskIdle];
	}
}

- (NSString *)name {

    return @"Endtrial";
}

- (LLState *)nextState {

//	if ([task mode] == kTaskIdle) {
	if ([task mode] != kTaskRunning) {
		return [[task stateSystem] stateNamed:@"Idle"];
    }
	else {
		return [[task stateSystem] stateNamed:@"Intertrial"];
	}
}

@end
