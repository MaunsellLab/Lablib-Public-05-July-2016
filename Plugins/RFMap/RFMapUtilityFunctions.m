//
//  UtilityFunctions.m
//  Experiment
//
//  Created by John Maunsell on Fri Apr 04 2003.
//  Copyright (c) 2004. All rights reserved.
//

#import "RF.h"
#import "RFMapUtilityFunctions.h"

#define kC50Squared			0.4
#define kDrivenRate			40.0
#define kSpontRate			5.0

void putParameterEvents(void) {

    long lValue;
	char *idString = "RFMap Version 1.0";
	
 	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];
	
// ??? Here we need additional test strings that give the screen parameters and eye calibration

    lValue = [[task defaults] integerForKey:RFStimTypeKey];
	[[task dataDoc] putEvent:@"stimulusType" withData:&lValue];
}

void requestReset(void) {

    if ([task mode] == kTaskIdle) {
        reset();
    }
    else {
        resetFlag = YES;
    }
}

void reset(void) {

    long resetType = 0;
    
	[[task dataDoc] putEvent:@"reset" withData:&resetType];
}

double spikeRateFromStimValue(double normalizedValue) {

	double vSquared;
	
	vSquared = normalizedValue * normalizedValue;
	return kDrivenRate *  vSquared / (vSquared + kC50Squared) + kSpontRate;
}

double valueFromIndex(long index, StimParams *pStimParams) {

	if (index < 0 || index >= pStimParams->levels) {
		return 0.0;
	}
	return	exp(log(pStimParams->maxValue) + log(pStimParams->factor) * 
									(pStimParams->levels - index - 1));
}
