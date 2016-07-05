//
//  VTIntervalOneState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTIntervalOneState.h" 
#import "UtilityFunctions.h"

@implementation VTIntervalOneState

- (void)stateAction {

	float stimulusValue, normalizedValue;
	
	long intervalMS = [[task defaults] integerForKey:VTIntervalMSKey];
	 
	stimulusValue = trial.stimulusValue;
	switch (trial.stimulusType) {
	case kElectricalStimulus:
		expireTime = [LLSystemUtil timeFromNow:intervalMS];
		normalizedValue = stimulusValue / [[task defaults] floatForKey:VTMaxCurrentKey];
		break;
	case kVisualStimulus:
	default:
		[stimuli runContrast:stimulusValue duration:intervalMS];
		normalizedValue = stimulusValue / [[task defaults] floatForKey:VTMaxContrastKey];
	}
	[[task dataDoc] putEvent:@"intervalOne" withData:&stimulusValue];	
    [[task synthDataSource] setSpikeRateHz:spikeRateFromStimValue(normalizedValue) atTime:[LLSystemUtil getTimeS]];
}

- (NSString *)name {

    return @"IntervalOne";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VTFixateKey] &&  ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		brokeDuringStim = (trial.stimulusInterval == kSecondInterval);
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if (((trial.stimulusType == kElectricalStimulus) && [LLSystemUtil timeIsPast:expireTime]) || 
						(trial.stimulusType == kVisualStimulus && ![stimuli stimulusOn])) {
		return [[task stateSystem] stateNamed:@"Poststim"];
	}
    return nil;
}


@end
