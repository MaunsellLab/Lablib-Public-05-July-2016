//
//  VIReactState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VIReactState.h"
#import "VIUtilities.h"
#import "UtilityFunctions.h"

#define kAlpha		(0.40 + 0.15 * trial.trialType)
#define kBeta		2.0

@implementation VIReactState

- (void)stateAction;
{
	float prob100;
	
	expireTime = [LLSystemUtil timeFromNow:([[task defaults] integerForKey:VIRespTimeMSKey] - [[task defaults] integerForKey:VITooFastMSKey])];
					
// Here we instruct the fake monkey to respond, using appropriate psychophysics.

	prob100 = 100.0 - 100.0 * exp(-exp(log(trial.targetAlphaChange / kAlpha) * kBeta));
    
//    prob100 = 100.0;
    
	if ((rand() % 100) < prob100) {
		[[task synthDataDevice] setEyeTargetOn:azimuthAndElevationForStimLoc(trial.targetPos, trial.attendState)];
        [[task synthDataDevice] setNextSaccadeTimeS:([LLSystemUtil getTimeS] + 0.100 + trial.trialType * 0.050)];
	}
}

- (NSString *)name {

    return @"React";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {							// switched to idle
		eotCode = extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[task defaults] boolForKey:VIFixateKey]) {		// no fixation requirement, give a reward
		eotCode = extendedEotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	else {
		if (![VIUtilities inWindow:fixWindow]) { // started a saccade after target onset            
            return [[task stateSystem] stateNamed:@"Saccade"];            
        }
    }
    if ([LLSystemUtil timeIsPast:expireTime]) {				// never reaponded: fail
        eotCode = extendedEotCode = kEOTFailed;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    return nil;
}

@end
