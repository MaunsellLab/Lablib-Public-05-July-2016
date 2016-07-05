//
//  SCStarttrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SCStarttrialState.h"
#import "UtilityFunctions.h"
#import "SCUtilities.h"
#import "SCDigitalOut.h"

@implementation SCStarttrialState

- (void)stateAction;
{
	long lValue, respLoc, wrongLoc;
	LLGabor *gabors[kLocations];
	FixWindowData fixWindowData, respWindowData, wrongWindowData;
    static long trialCount = 0;
	
	eotCode = -1;
	
// Prepare structures describing the fixation and response windows;
	
	fixWindowData.index = [[task eyeCalibrator] nextCalibrationPosition];
	[[task synthDataDevice] setOffsetDeg:[[task eyeCalibrator] calibrationOffsetPointDeg]];			// keep synth data on offset fixation

// fixWindow is not being updated

	fixWindowData.windowDeg = [fixWindow rectDeg];
    fixWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:fixWindowData.windowDeg];
    [fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:SCFixWindowWidthDegKey]];

	gabors[kAttend0] = [stimuli gabor0];
	gabors[kAttend1] = [stimuli gabor1];
	respLoc = (trial.validTrial) ? trial.attendLoc : 1 - attendLoc;
	wrongLoc = (trial.validTrial) ? 1 - attendLoc : trial.attendLoc;
	[respWindow setAzimuthDeg:[gabors[respLoc] azimuthDeg] elevationDeg:[gabors[respLoc] elevationDeg]];
    if ((attendLoc == 0 && trial.validTrial) || (attendLoc == 1 && !trial.validTrial)) {
        [respWindow setWidthAndHeightDeg:[[task defaults] floatForKey:SCRespWindowWidthDegKey]];
    }
    else {
     	[respWindow setWidthAndHeightDeg:[[task defaults] floatForKey:SCRespWindowWidthDegKey] * 1]; // to make the more eccentric window bigger
    }
	respWindowData.index = 0;
	respWindowData.windowDeg = [respWindow rectDeg];
	respWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:respWindowData.windowDeg];
	[wrongWindow setAzimuthDeg:[gabors[wrongLoc] azimuthDeg] elevationDeg:[gabors[wrongLoc] elevationDeg]];
    if ((attendLoc == 1 && trial.validTrial) || (attendLoc ==0 && !trial.validTrial)){
        [wrongWindow setWidthAndHeightDeg:[[task defaults] floatForKey:SCRespWindowWidthDegKey]];
    }
    else {
     	[wrongWindow setWidthAndHeightDeg:[[task defaults] floatForKey:SCRespWindowWidthDegKey] * 1];
    }
	wrongWindowData.index = 0;
	wrongWindowData.windowDeg = [wrongWindow rectDeg];
	wrongWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:wrongWindowData.windowDeg];

// Stop data collection before this block of events, and force all the data to be readcollectorTimer
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
	[[task dataController] readDataFromDevices];		// flush data buffers
	[[task collectorTimer] fire];
	[[task dataDoc] putEvent:@"trialStart" withData:&trial.targetIndex];
	[digitalOut outputEvent:kTrialStartCode withData:trialCount++];
	
	[[task dataDoc] putEvent:@"trial" withData:&trial];
	lValue = 0;
	[[task dataDoc] putEvent:@"sampleZero" withData:&lValue];	// for now, it has no practical functions
	[[task dataDoc] putEvent:@"spikeZero" withData:&lValue];
	
// Restart data collection immediately after declaring the zerotimes

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];
	[[task dataDoc] putEvent:@"eyeLeftCalibration" withData:[[task eyeCalibrator] calibrationDataForEye:kLeftEye]];
	[[task dataDoc] putEvent:@"eyeRightCalibration" withData:[[task eyeCalibrator] calibrationDataForEye:kRightEye]];
	[[task dataDoc] putEvent:@"eyeWindow" withData:&fixWindowData];
	[[task dataDoc] putEvent:@"responseWindow" withData:&respWindowData];
	[[task dataDoc] putEvent:@"wrongWindow" withData:&wrongWindowData];
}

- (NSString *)name {

    return @"SCStarttrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return  [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([[task defaults] boolForKey:SCFixateKey] && [SCUtilities inWindow:fixWindow]) {
		return [[task stateSystem] stateNamed:@"SCBlocked"];
	}
	else {
		return [[task stateSystem] stateNamed:@"SCFixon"];
	} 
}

@end
