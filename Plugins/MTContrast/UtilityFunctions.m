//
//  UtilityFunctions.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "MTC.h"
#import "UtilityFunctions.h"

#define kC50Squared			0.0225
#define kDrivenRate			100.0
#define kSpontRate			15.0

void announceEvents(void) {

    long lValue;
    long floatValue;
	char *idString = "MTContrast Version 1.0";
	
 	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];

	[[task dataDoc] putEvent:@"contrastStimParams" withData:(Ptr)getStimParams()];
	[[task dataDoc] putEvent:@"gabor" withData:(Ptr)[[stimuli gabor] gaborData]];
    floatValue = [[task defaults] floatForKey:MTCEccentricityDegKey];
	[[task dataDoc] putEvent:@"eccentricityDeg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:MTCPolarAngleDegKey];
	[[task dataDoc] putEvent:@"polarAngleDeg" withData:(Ptr)&floatValue];
    floatValue = [[task defaults] floatForKey:MTCSeparationDegKey];
	[[task dataDoc] putEvent:@"separationDeg" withData:(Ptr)&floatValue];

    lValue = [[task defaults] integerForKey:MTCStimDurationMSKey];
	[[task dataDoc] putEvent:@"stimDurationMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:MTCInterstimMSKey];
	[[task dataDoc] putEvent:@"interstimMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:MTCInterstimMSKey];
	[[task dataDoc] putEvent:@"stimLeadMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:MTCStimLeadMSKey];
	[[task dataDoc] putEvent:@"responseTimeMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:MTCTooFastMSKey];
	[[task dataDoc] putEvent:@"tooFastTimeMS" withData:(Ptr)&lValue];
    lValue = [[task defaults] integerForKey:MTCTriesKey];
	[[task dataDoc] putEvent:@"tries" withData:(Ptr)&lValue];
	lValue = [[task defaults] integerForKey:MTCStimRepsPerBlockKey];
	[[task dataDoc] putEvent:@"stimRepsPerBlock" withData:(void *)&lValue];
}

 NSPoint azimuthAndElevationForStimIndex(long index)
 {
	float polarAngleRad, eccentricityDeg, separationDeg;
	NSPoint aziEle;

	eccentricityDeg = [[task defaults] floatForKey:MTCEccentricityDegKey];
	separationDeg = [[task defaults] floatForKey:MTCSeparationDegKey];
	polarAngleRad = ([[task defaults] floatForKey:MTCPolarAngleDegKey] + 
					(((index % 2) ? -separationDeg : separationDeg) / 2.0)) / kDegPerRadian;
	aziEle.x = eccentricityDeg * cos(polarAngleRad);
	aziEle.y = eccentricityDeg * sin(polarAngleRad);
	return aziEle;
}

extern float contrastFromIndex(short index)
{
	return(valueFromIndex(index, getStimParams()));
}

StimParams *getStimParams(void)
{
	static StimParams params;
	
	params.levels = [[task defaults] integerForKey:MTCContrastsKey];
	params.maxValue = [[task defaults] floatForKey:MTCMaxContrastKey];
	params.factor = [[task defaults] floatForKey:MTCContrastFactorKey];
	return &params;
}

void putBlockDataEvents(long blocksDone)
{
	long value;

	value = stimDoneThisBlock(blocksDone);
	[[task dataDoc] putEvent:@"blockStimDone" withData:(void *)&value];
	[[task dataDoc] putEvent:@"blocksDone" withData:(void *)&blocksDone];
}

long repsDoneAtLoc(long loc) {

	long index, done;
	
	for (index = 0, done = LONG_MAX; index < [[task defaults] integerForKey:MTCContrastsKey]; index++) {
		done = MIN(done, stimDone[loc][index]);
	}
	return done;
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

float spikeRateFromStimValue(float normalizedValue) {

	double vSquared;
	
	vSquared = normalizedValue * normalizedValue;
	return kDrivenRate *  vSquared / (vSquared + kC50Squared) + kSpontRate;
}

// Return the number of stimulus repetitions in a block (kLocations * repsPerBlock * contrasts)  

long stimPerBlock(void) {

	return kLocations * [[task defaults] integerForKey:MTCStimRepsPerBlockKey] * 
									[[task defaults] integerForKey:MTCContrastsKey];
}

// Return the number of stimuli completed in the current block  

long stimDoneThisBlock(long blocksDone) {

	long loc, c, contrasts, reps, done[kLocations];
	
	contrasts = [[task defaults] integerForKey:MTCContrastsKey];
	reps = [[task defaults] integerForKey:MTCStimRepsPerBlockKey];
	for (loc = 0; loc < kLocations; loc++) {
		for (c = 0, done[loc] = LONG_MAX; c < contrasts; c++) {
			done[loc] = MIN(done[loc], stimDone[loc][c]);
		}
		done[loc] = MIN(done[loc] - blocksDone * reps, (blocksDone + 1) * reps);
	}
	return (done[0] + done[1]);
}

void updateBlockStatus(void) {

	long index, contrasts;

	contrasts = [[task defaults] integerForKey:MTCContrastsKey];
	blockStatus.presentationsPerLoc = contrasts * [[task defaults] integerForKey:MTCStimRepsPerBlockKey]; 
	blockStatus.locsPerBlock = kLocations;
	blockStatus.blockLimit = [[task defaults] integerForKey:MTCBlockLimitKey];
	blockStatus.presentationsDoneThisLoc = -(blockStatus.blocksDone * blockStatus.presentationsPerLoc);
	for (index = 0; index < contrasts; index++) {
		blockStatus.presentationsDoneThisLoc += stimDone[blockStatus.attendLoc][index];
	}
	if (blockStatus.presentationsDoneThisLoc >= blockStatus.presentationsPerLoc) {
		blockStatus.attendLoc = ((blockStatus.attendLoc + 1) % blockStatus.locsPerBlock); 
		blockStatus.instructsDone = 0; 
		blockStatus.presentationsDoneThisLoc = -(blockStatus.blocksDone * blockStatus.presentationsPerLoc);
		for (index = 0; index < contrasts; index++) {
			blockStatus.presentationsDoneThisLoc += stimDone[blockStatus.attendLoc][index];
		}
		if (++blockStatus.locsDoneThisBlock >= blockStatus.locsPerBlock) {
			blockStatus.blocksDone++;
			blockStatus.locsDoneThisBlock = 0;
		}
	}
}
	
float valueFromIndex(long index, StimParams *pStimParams)
{
	short c, contrasts;
	float contrast, level, contrastFactor;
	
	contrasts = pStimParams->levels;
	contrastFactor = pStimParams->factor;
	switch (contrasts) {
	case 1:								// Just the 100% stimulus
		contrast = pStimParams->maxValue;
		break;
	case 2:								// Just 100% and 0% contrast stimuli
		contrast = (index == 0) ? 0 : pStimParams->maxValue;
		break;
	default:							// Other contrasts as well
		if (index == 0) {
			contrast = 0;
		}
		else {
			level = pStimParams->maxValue;
			for (c = contrasts - 1; c > index; c--) {
				level *= contrastFactor;
			}
			contrast = level;
		}
	}
	return(contrast);
}
