//
//  RFIntertrialState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFIntertrialState.h"
#import "RFMapUtilityFunctions.h"

@implementation RFIntertrialState

- (void)stateAction {

	behaviorMode = kBehaviorRunning;
	expireTime = [LLSystemUtil timeFromNow:[[NSUserDefaults standardUserDefaults] integerForKey:RFIntertrialMSKey]];
	eotCode = kEOTCorrect;			// Default eot code is correct
	
	trial.stimulusType = [[NSUserDefaults standardUserDefaults] integerForKey:RFStimTypeKey];

// update the fixtation and response windows

    [fixWindow setWidthAndHeightDeg:[[NSUserDefaults standardUserDefaults] floatForKey:RFFixWindowWidthDegKey]];
}

- (NSString *)name {

    return @"Intertrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskStopping) {
        eotCode = kEOTQuit;
        return [[task stateSystem] stateNamed:@"Endtrial"];
    }
    else if ([LLSystemUtil timeIsPast:expireTime]) {
        return [[task stateSystem] stateNamed:@"Starttrial"];
    }
    return nil;
}

@end
