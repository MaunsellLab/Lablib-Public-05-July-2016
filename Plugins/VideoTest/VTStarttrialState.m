//
//  VTStarttrialState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VTStarttrialState.h"

@implementation VTStarttrialState

- (void)stateAction {

	long lValue, interval;
	FixWindowData fixWindowData, respWindowData[kIntervals];

// Prepare structures describing the fixation and response windows;
	
	fixWindowData.index = [[task eyeCalibrator] nextCalibrationPosition];
	[[task synthDataSource] setOffsetDeg:[[task eyeCalibrator] offsetDeg]];			// keep synth data on offset fixation
    fixWindowData.windowDeg = [fixWindow rectDeg];
    fixWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:fixWindowData.windowDeg];
	for (interval = kFirst; interval < kIntervals; interval++) {
		[respWindows[interval] setWidthAndHeightDeg:[[task defaults] floatForKey:VTRespWindowWidthDegKey]];
		respWindowData[interval].index = interval;
		respWindowData[interval].windowDeg = [respWindows[interval] rectDeg];
		respWindowData[interval].windowUnits = [[task eyeCalibrator] 
				unitRectFromDegRect:respWindowData[interval].windowDeg];
	}

// Stop data collection before this block of events

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
	[[task dataController] readDataFromDevices];
	[[task collectorTimer] fire];

// For when this gets upgraded to use data devices:

	[[task dataDoc] putEvent:@"trialStart" withData:&trial.stimulusIndex];
	[[task dataDoc] putEvent:@"trial" withData:&trial];
	lValue = kSamplePeriodMS;
	[[task dataDoc] putEvent:@"sampleZero" withData:&lValue];
	lValue = kTimestampTickMS;
	[[task dataDoc] putEvent:@"spikeZero" withData:&lValue];

// Restart data collection immediately after declaring the zerotimes

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];
	[[task dataDoc] putEvent:@"eyeCalibration" withData:[[task eyeCalibrator] calibrationData]];
	[[task dataDoc] putEvent:@"eyeWindow" withData:&fixWindowData];
	[[task dataDoc] putEvent:@"responseWindow" withData:&respWindowData[kFirst]];
	[[task dataDoc] putEvent:@"responseWindow" withData:&respWindowData[kSecond]];
}

- (NSString *)name {

    return @"Starttrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return  [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VTFixateKey] && [fixWindow inWindowDeg:[task currentEyeDeg]]) {
		return [[task stateSystem] stateNamed:@"Blocked"];
	}
	else {
		return [[task stateSystem] stateNamed:@"Fixon"];
	} 
}

@end
