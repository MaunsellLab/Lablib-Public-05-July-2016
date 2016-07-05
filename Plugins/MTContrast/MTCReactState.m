//
//  MTCReactState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCReactState.h"
#import "UtilityFunctions.h"

#define kAlpha		10.0
#define kBeta		2.0

@implementation MTCReactState

- (void)stateAction;
{
	float prob100;
	
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:MTCRespTimeMSKey] -
                    [[task defaults] integerForKey:MTCTooFastMSKey]];
					
// Here we instruct the fake monkey to respond, using appropriate psychophysics.

	prob100 = 100.0 - 50.0 * exp(-exp(log(trial.targetContrastPC / kAlpha) * kBeta));
	if ((rand() % 100) < prob100) {
		[[task synthDataDevice] setEyeTargetOn:azimuthAndElevationForStimIndex(trial.attendLoc)];
	}
}

- (NSString *)name {

    return @"React";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {							// switched to idle
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[task defaults] boolForKey:MTCFixateKey]) {
		eotCode = kEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	else {
		if (![fixWindow inWindowDeg:[task currentEyeDeg]]) {   // started a saccade
			return [[task stateSystem] stateNamed:@"Saccade"];
		}
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kEOTFailed;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    return nil;
}

@end
