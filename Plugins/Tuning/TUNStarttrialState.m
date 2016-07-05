//
//  TUNStarttrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUNStarttrialState.h"
#import "UtilityFunctions.h"

@implementation TUNStarttrialState

- (void)stateAction {

	long lValue;
	FixWindowData fixWindowData;

// Prepare structures describing the fixation and response windows;
	
	fixWindowData.index = [[task eyeCalibrator] nextCalibrationPosition];
    fixWindowData.windowDeg = [fixWindow rectDeg];
    fixWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:fixWindowData.windowDeg];
    [fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:TUNFixWindowWidthDegKey]];
	[[task synthDataDevice] setOffsetDeg:[[task eyeCalibrator] calibrationOffsetPointDeg]];			// keep synth data on offset fixation

// Stop data collection before this block of events, and force all the data to be readcollectorTimer
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
	[[task dataController] readDataFromDevices];
	[[task collectorTimer] fire];
	[[task dataDoc] putEvent:@"trialStart" withData:&testParams.testTypeIndex];
	[[task dataDoc] putEvent:@"trial" withData:&trial];
	[[task dataDoc] putEvent:@"testParams" withData:&testParams];
	lValue = 0;
	[[task dataDoc] putEvent:@"sampleZero" withData:&lValue];
	[[task dataDoc] putEvent:@"spikeZero" withData:&lValue];
	
// Restart data collection immediately after declaring the zerotimes

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];
	[[task dataDoc] putEvent:@"eyeCalibration" withData:[[task eyeCalibrator] calibrationData]];
	[[task dataDoc] putEvent:@"eyeWindow" withData:&fixWindowData];
	[[task dataDoc] putEvent:@"blockStatus" withData:(void *)&blockStatus];
}

- (NSString *)name {

    return @"StartTrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:TUNFixateKey] && [fixWindow inWindowDeg:[task currentEyeDeg]]) {
		return [[task stateSystem] stateNamed:@"Blocked"];
	}
	else {
		return [[task stateSystem] stateNamed:@"Fixon"];
	} 
}

@end
