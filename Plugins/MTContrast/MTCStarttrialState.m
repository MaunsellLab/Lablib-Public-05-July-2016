//
//  MTCStarttrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTCStarttrialState.h"
#import "UtilityFunctions.h"

@implementation MTCStarttrialState

- (void)stateAction {

	long lValue, index;
	NSPoint aziEle;
	FixWindowData fixWindowData, respWindowData[kLocations];

// Prepare structures describing the fixation and response windows;
	
	fixWindowData.index = [[task eyeCalibrator] nextCalibrationPosition];
    fixWindowData.windowDeg = [fixWindow rectDeg];
    fixWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:fixWindowData.windowDeg];
    [fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:MTCFixWindowWidthDegKey]];
	[[task synthDataDevice] setOffsetDeg:[[task eyeCalibrator] calibrationOffsetPointDeg]];			// keep synth data on offset fixation
	for (index = 0; index < kLocations; index++) {
		aziEle = azimuthAndElevationForStimIndex(index);
		[respWindows[index] setAzimuthDeg:aziEle.x elevationDeg:aziEle.y];
		[respWindows[index] setWidthAndHeightDeg:[[task defaults] floatForKey:MTCRespWindowWidthDegKey]];
		respWindowData[index].index = index;
		respWindowData[index].windowDeg = [respWindows[index] rectDeg];
		respWindowData[index].windowUnits = [[task eyeCalibrator] 
				unitRectFromDegRect:respWindowData[index].windowDeg];
	}

// Stop data collection before this block of events, and force all the data to be readcollectorTimer
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
	[[task dataController] readDataFromDevices];
	[[task collectorTimer] fire];
	[[task dataDoc] putEvent:@"trialStart" withData:&trial.targetIndex];
	[[task dataDoc] putEvent:@"trial" withData:&trial];
	lValue = 0;
	[[task dataDoc] putEvent:@"sampleZero" withData:&lValue];
	[[task dataDoc] putEvent:@"spikeZero" withData:&lValue];
	
// Restart data collection immediately after declaring the zerotimes

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];
	[[task dataDoc] putEvent:@"eyeCalibration" withData:[[task eyeCalibrator] calibrationData]];
	[[task dataDoc] putEvent:@"eyeWindow" withData:&fixWindowData];
	[[task dataDoc] putEvent:@"responseWindow" withData:&respWindowData[0]];
	[[task dataDoc] putEvent:@"responseWindow" withData:&respWindowData[1]];
}

- (NSString *)name {

    return @"StartTrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:MTCFixateKey] && [fixWindow inWindowDeg:[task currentEyeDeg]]) {
		return [[task stateSystem] stateNamed:@"Blocked"];
	}
	else {
		return [[task stateSystem] stateNamed:@"Fixon"];
	} 
}

@end
