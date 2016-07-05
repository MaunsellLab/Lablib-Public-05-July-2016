//
//  UtilityFunctions.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "TUN.h"
#import "UtilityFunctions.h"

#define kC50Squared			0.0225
#define kDrivenRate			100.0
#define kSpontRate			15.0

void announceEvents(void) {

    long lValue;
    long floatValue;
	char *idString = "Tuning Version 1.0";
	
 	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];

	[[task dataDoc] putEvent:@"testParams" withData:&testParams];
	[[task dataDoc] putEvent:@"gabor" withData:(Ptr)[[stimuli gabor] gaborData]];
	[[task dataDoc] putEvent:@"randomDots" withData:(Ptr)[[stimuli randomDots] dotsData]];
	[[task dataDoc] putEvent:@"testParams" withData:&testParams];
    floatValue = [[task defaults] floatForKey:TUNEccentricityDegKey];
	[[task dataDoc] putEvent:@"eccentricityDeg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:TUNPolarAngleDegKey];
	[[task dataDoc] putEvent:@"polarAngleDeg" withData:(Ptr)&floatValue];

    lValue = [[task defaults] integerForKey:TUNPreStimMSKey];
	[[task dataDoc] putEvent:@"preStimMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:TUNStimDurationMSKey];
	[[task dataDoc] putEvent:@"stimDurationMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:TUNInterstimMSKey];
	[[task dataDoc] putEvent:@"interstimMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:TUNInterstimMSKey];
	[[task dataDoc] putEvent:@"stimLeadMS" withData:(Ptr)&lValue];
	lValue = [[task defaults] integerForKey:TUNStimPerTrialKey];
	[[task dataDoc] putEvent:@"stimRepsPerBlock" withData:(void *)&lValue];
}

NSPoint azimuthAndElevationForStimIndex(long index) 
{
	float polarAngleRad, eccentricityDeg;
	NSPoint aziEle;

	eccentricityDeg = [[task defaults] floatForKey:TUNEccentricityDegKey];
	polarAngleRad = [[task defaults] floatForKey:TUNPolarAngleDegKey] * kRadiansPerDeg;
	aziEle.x = eccentricityDeg * cos(polarAngleRad);
	aziEle.y = eccentricityDeg * sin(polarAngleRad);
	return aziEle;
}

void requestReset(void)
{

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

float spikeRateFromStimValue(float normalizedValue) {

	double vSquared;
	
	vSquared = normalizedValue * normalizedValue;
	return kDrivenRate *  vSquared / (vSquared + kC50Squared) + kSpontRate;
}
