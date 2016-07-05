//
//  VCANStarttrialState.m
//  Experiment
//
//  Copyright (c) 2012. All rights reserved.
//

#import "VCANStarttrialState.h"
#import "VCANUtilities.h"
#import "UtilityFunctions.h"

@implementation VCANStarttrialState

- (void)stateAction {

	long lValue, index;
	float fValue;
	NSPoint aziEle;
	FixWindowData fixWindowData, respWindowData[kStimLocs];
    static long trialCount = 0;
    
// Prepare structures describing the fixation and response windows;
	
	fixWindowData.index = [[task eyeCalibrator] nextCalibrationPosition];
    fixWindowData.windowDeg = [fixWindow rectDeg];
    fixWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:fixWindowData.windowDeg];
    [fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:VCANFixWindowWidthDegKey]];
	[[task synthDataDevice] setOffsetDeg:[[task eyeCalibrator] calibrationOffsetPointDeg]];			// keep synth data on offset fixation
	for (index = 0; index < kStimLocs; index++) {
		aziEle = azimuthAndElevationForStimLoc(index, trial.attendState);
		[respWindows[index] setAzimuthDeg:aziEle.x elevationDeg:aziEle.y];
		[respWindows[index] setWidthAndHeightDeg:[[task defaults] floatForKey:VCANRespWindowWidthDegKey]];
		respWindowData[index].index = index;
		respWindowData[index].windowDeg = [respWindows[index] rectDeg];
		respWindowData[index].windowUnits = [[task eyeCalibrator] 
				unitRectFromDegRect:respWindowData[index].windowDeg];
	}

// We need to drain all the data from the data source.  We do this by stopping data collection, firing the collection
// routine, and waiting for the collection to occur. We restar data collection immediately after declaring the zerotimes
    
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
	[[task dataController] readDataFromDevices];
	[[task collectorTimer] fire];
	[[task dataDoc] putEvent:@"trialStart" withData:&trial.targetIndices[trial.attendLoc]];
	[[task dataDoc] putEvent:@"trialCount" withData:&trialCount];
	[digitalOut outputEvent:kTrialStartCode withData:trialCount++];
	[[task dataDoc] putEvent:@"trial" withData:&trial];
	lValue = 0;
	[[task dataDoc] putEvent:@"sampleZero" withData:&lValue];
	[[task dataDoc] putEvent:@"spikeZero" withData:&lValue];
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];
	[[task dataDoc] putEvent:@"eyeLeftCalibration" withData:[[task eyeCalibrator] calibrationDataForEye:kLeftEye]];
	[[task dataDoc] putEvent:@"eyeRightCalibration" withData:[[task eyeCalibrator] calibrationDataForEye:kRightEye]];
	[[task dataDoc] putEvent:@"eyeWindow" withData:&fixWindowData];
	for (index = 0; index < kStimLocs; index++) {
		[[task dataDoc] putEvent:@"responseWindow" withData:&respWindowData[index]];
	}
	fValue = [[task defaults] floatForKey:VCANRelDistContrastKey];
	[[task dataDoc] putEvent:@"relDistContrast" withData:&fValue];
}

- (NSString *)name {

    return @"StartTrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		extendedEotCode = kEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:VCANFixateKey] && [VCANUtilities inWindow:fixWindow]) {
		return [[task stateSystem] stateNamed:@"Blocked"];
	}
	else {
		return [[task stateSystem] stateNamed:@"Fixon"];
	} 
}

@end
