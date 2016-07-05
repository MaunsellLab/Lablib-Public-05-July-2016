//
//  VCANReactState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANReactState.h"
#import "VCANUtilities.h"
#import "UtilityFunctions.h"

#define kAlpha		20
#define kBeta		2.0

@implementation VCANReactState

- (void)stateAction;
{
	float prob100;
	
	expireTime = [LLSystemUtil timeFromNow:([[task defaults] integerForKey:VCANRespTimeMSKey] - [[task defaults] integerForKey:VCANTooFastMSKey])];
					
// Here we instruct the fake monkey to respond, using appropriate psychophysics.

	prob100 = 100.0 - 100.0 * exp(-exp(log(trial.targetContrastChangePC[trial.attendLoc] / kAlpha) * kBeta));
    
    prob100 = 100.0;
    
	if ((rand() % 100) < prob100) {
		[[task synthDataDevice] setEyeTargetOn:azimuthAndElevationForStimLoc(trial.attendLoc, trial.attendState)];
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
	if (![[task defaults] boolForKey:VCANFixateKey]) {		// no fixation requirement, give a reward
		eotCode = extendedEotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	else {
		if (![VCANUtilities inWindow:fixWindow]) { // started a saccade after target onset            
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
