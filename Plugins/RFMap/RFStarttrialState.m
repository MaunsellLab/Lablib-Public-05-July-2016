//
//  RFStarttrialState.m
//  Experiment
//
//  Created by John Maunsell on Thu May 29 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RFStarttrialState.h"

@implementation RFStarttrialState

- (void)stateAction {

	long lValue;
	FixWindowData fixWindowData;

// Force the fixspot to zero, because we move the calibrator in this task.

	[[stimuli fixSpot] setAzimuthDeg:0.0 elevationDeg:0.0];
	
// Prepare structures describing the fixation and response windows;
	
	fixWindowData.index = [[task eyeCalibrator] nextCalibrationPosition];
	[[task synthDataDevice] setOffsetDeg:[[task eyeCalibrator] calibrationOffsetPointDeg]];			// keep synth data on offset fixation
    fixWindowData.windowDeg = [fixWindow rectDeg];
    fixWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:fixWindowData.windowDeg];
	
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
	[[task dataController] readDataFromDevices];
	[[task collectorTimer] fire];
	lValue = kSamplePeriodMS;
	[[task dataDoc] putEvent:@"sampleZero" withData:&lValue];
	lValue = kTimestampTickMS;
	[[task dataDoc] putEvent:@"spikeZero" withData:&lValue];

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];
	[[task dataDoc] putEvent:@"eyeCalibration" withData:[[task eyeCalibrator] calibrationData]];
	[[task dataDoc] putEvent:@"eyeWindow" withData:&fixWindowData];
}

- (NSString *)name {

    return @"Starttrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[NSUserDefaults standardUserDefaults] boolForKey:RFDoFixateKey] && [fixWindow inWindowDeg:[task currentEyeDeg]]) {
		return [[task stateSystem] stateNamed:@"Blocked"];
	}
	else {
		return [[task stateSystem] stateNamed:@"Fixon"];
	} 
}

@end
