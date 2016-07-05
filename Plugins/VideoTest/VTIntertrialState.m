//
//  VTIntertrialState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTIntertrialState.h"
#import "UtilityFunctions.h"

@implementation VTIntertrialState

- (void)stateAction {

	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:VTIntertrialMSKey]];
	eotCode = kEOTCorrect;				// Default eot code is correct
	brokeDuringStim = NO;				// flag for fixation break during stimulus presentation	
	trial.stimulusIndex = [trialBlock nextTrialIndex];
	if (trial.stimulusIndex < 0) {		// no trials remaining
		[task setMode:kTaskIdle];
		return;
	}
	
	trial.stimulusType = [[task defaults] integerForKey:VTStimTypeKey];
	trial.stimulusValue = valueFromIndex(trial.stimulusIndex, getStimParams(trial.stimulusType));
	trial.stimulusInterval = rand() % 2;

// update the fixtation and response windows

    [fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:VTFixWindowWidthDegKey]];
	[respWindows[kFirst] setAzimuthDeg:[[task defaults] floatForKey:VTRespWindow0AziKey]];
	[respWindows[kFirst] setElevationDeg:[[task defaults] floatForKey:VTRespWindow0EleKey]];
	[respWindows[kSecond] setAzimuthDeg:[[task defaults] floatForKey:VTRespWindow1AziKey]];
	[respWindows[kSecond] setElevationDeg:[[task defaults] floatForKey:VTRespWindow1EleKey]];

	trial.respAziDeg = [respWindows[trial.stimulusInterval] azimuthDeg];
	trial.respEleDeg = [respWindows[trial.stimulusInterval] elevationDeg];
}

- (NSString *)name {

    return @"Intertrial";
}

- (LLState *)nextState {

    if ([task mode] == kTaskIdle) {
        eotCode = kEOTQuit;
        return [[task stateSystem] stateNamed:@"Endtrial"];
    }
    else if ([LLSystemUtil timeIsPast:expireTime]) {
        return [[task stateSystem] stateNamed:@"Starttrial"];
    }
    return nil;
}

@end
