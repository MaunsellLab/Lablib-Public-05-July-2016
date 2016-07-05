//
//  VTReactState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTReactState.h"


@implementation VTReactState

- (void)stateAction {

	double prob100, alpha, beta, factor;
	
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTRespTimeMSKey] -
                    [[task defaults] integerForKey:VTTooFastMSKey]];
					
// Here we instruct the fake monkey to respond, using appropriate psychophysics.

	alpha = 10.0;
	beta = 2.0;
	prob100 = 100.0 - 50.0 * exp(-exp(log(trial.stimulusValue / alpha) * beta));
	factor = ((rand() % 100) < prob100) ? 1 : -1;
    [[task synthDataSource] setEyeTargetOn:
			NSMakePoint(factor * trial.respAziDeg, factor * trial.respEleDeg)];
}

- (NSString *)name {

    return @"React";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {							// switched to idle
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (![[task defaults] boolForKey:VTFixateKey]) {
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
