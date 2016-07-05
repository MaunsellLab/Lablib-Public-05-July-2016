//
//  UtilityFunctions.m
//  Experiment
//
//  Created by John Maunsell on Fri Apr 04 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "VT.h"
#import "UtilityFunctions.h"

#define kC50Squared			0.4
#define kDrivenRate			40.0
#define kSpontRate			5.0

void announceEvents(void) {

    long lValue;
	float fValue;
	char *idString = "Experiment Version 1.1";
	
 	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];
 	[[task dataDoc] putEvent:@"displayCalibration" withData:[stimuli displayParameters]];

    lValue = [[task defaults] integerForKey:VTStimTypeKey];
	[[task dataDoc] putEvent:@"stimulusType" withData:&lValue];
	[[task dataDoc] putEvent:@"contrastStimParams" withData:(Ptr)getStimParams(kVisualStimulus)];
	[[task dataDoc] putEvent:@"gabor" withData:(Ptr)[stimuli->gabor gaborData]];
	[[task dataDoc] putEvent:@"currentStimParams" withData:(Ptr)getStimParams(kElectricalStimulus)];
    fValue = [[task defaults] floatForKey:VTFrequencyHzKey];
	[[task dataDoc] putEvent:@"frequencyHz" withData:(Ptr)&fValue];
    lValue = [[task defaults] integerForKey:VTPulseWidthUSKey];
	[[task dataDoc] putEvent:@"pulseWidthUS" withData:&lValue];
    lValue = [[task defaults] integerForKey:VTUAPerVKey];
	[[task dataDoc] putEvent:@"uAPerV" withData:&lValue];
    lValue = [[task defaults] integerForKey:VTPreintervalMSKey];
	[[task dataDoc] putEvent:@"preIntervalMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VTIntervalMSKey];
	[[task dataDoc] putEvent:@"intervalMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VTGapMSKey];
	[[task dataDoc] putEvent:@"gapMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VTPostintervalMSKey];
	[[task dataDoc] putEvent:@"postStimuliMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VTRespTimeMSKey];
	[[task dataDoc] putEvent:@"responseTimeMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VTTooFastMSKey];
	[[task dataDoc] putEvent:@"tooFastTimeMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VTTriesKey];
	[[task dataDoc] putEvent:@"tries" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:VTBlockLimitKey];
	[[task dataDoc] putEvent:@"blockLimit" withData:(Ptr)&lValue];
}

StimParams *getStimParams(long stimType) {

	static StimParams params;
	
	switch (stimType) {
	case kVisualStimulus:
		params.levels = [[task defaults] integerForKey:VTContrastsKey];
		params.maxValue = [[task defaults] floatForKey:VTMaxContrastKey];
		params.factor = [[task defaults] floatForKey:VTContrastFactorKey];
		break;
	case kElectricalStimulus:
		params.levels = [[task defaults] integerForKey:VTCurrentsKey];
		params.maxValue = [[task defaults] floatForKey:VTMaxCurrentKey];
		params.factor = [[task defaults] floatForKey:VTCurrentFactorKey];
		break;
	}
	return &params;
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

StimTrainData *stimTrainParameters(double amplitudeUA) {

	static StimTrainData data;
	
	data.amplitudeUA = amplitudeUA;
	data.DAChannel = [[task defaults] integerForKey:VTDAChannelKey];
	data.doGate = [[task defaults] boolForKey:VTDoGateKey];
	data.doPulseMarkers = [[task defaults] boolForKey:VTDoMarkerPulsesKey];
	data.durationMS = [[task defaults] integerForKey:VTIntervalMSKey];
	data.frequencyHZ = [[task defaults] floatForKey:VTFrequencyHzKey];
	data.gateBit = [[task defaults] integerForKey:VTGateBitKey];
	data.pulseMarkerBit = [[task defaults] integerForKey:VTMarkerPulseBitKey];
	data.pulseWidthUS = [[task defaults] integerForKey:VTPulseWidthUSKey];
	data.UAPerV = [[task defaults] integerForKey:VTUAPerVKey];
	
	return &data;
}

double valueFromIndex(long index, StimParams *pStimParams) {

	if (index < 0 || index >= pStimParams->levels) {
		return 0.0;
	}
	return	exp(log(pStimParams->maxValue) + log(pStimParams->factor) * 
									(pStimParams->levels - index - 1));
}
