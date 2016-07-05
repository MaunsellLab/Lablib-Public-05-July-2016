//
//  UtilityFunctions.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "SC.h"
#import "UtilityFunctions.h"

#define kC50Squared			0.09
#define kDrivenRate			100.0
#define kSpontRate			5.0


void announceEvents(void) {

    long lValue;
	char *idString = "SpotChange Version 1.0";
	
 	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];

	[[task dataDoc] putEvent:@"blockStatus" withData:&blockStatus];
	[[task dataDoc] putEvent:@"behaviorSetting" withData:(Ptr)getBehaviorSetting()];
	[[task dataDoc] putEvent:@"stimSetting" withData:(Ptr)getStimSetting()];
	[[task dataDoc] putEvent:@"gabor0" withData:(Ptr)[[stimuli gabor0] gaborData]];
	[[task dataDoc] putEvent:@"gabor1" withData:(Ptr)[[stimuli gabor1] gaborData]];

    lValue = [[task defaults] integerForKey:SCStimDurationMSKey];
	[[task dataDoc] putEvent:@"stimDurationMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:SCInterstimMSKey];
	[[task dataDoc] putEvent:@"interstimMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:SCRespTimeMSKey];
	[[task dataDoc] putEvent:@"responseTimeMS" withData:&lValue];
	lValue = [[task defaults] integerForKey:SCMaxTargetMSKey];
	[[task dataDoc] putEvent:@"maxTargetTimeMS" withData:(void *)&lValue];
	lValue = [[task defaults] integerForKey:SCMinTargetMSKey];
	[[task dataDoc] putEvent:@"minTargetTimeMS" withData:(void *)&lValue];

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

void updateCatchTrialPC(void) {

	float lambda, catchTrialMaxPC;
	float minTargetS, meanTargetS, maxTargetS, meanRateHz;
	long stimulusMS, interstimMS, maxTargetIndex;

	stimulusMS = [[task defaults] integerForKey:SCStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:SCInterstimMSKey];
	meanRateHz = 1000.0 / (stimulusMS + interstimMS);
	minTargetS = [[task defaults] integerForKey:SCMinTargetMSKey] / 1000.0;
	meanTargetS = [[task defaults] integerForKey:SCMeanTargetMSKey] / 1000.0;
	maxTargetIndex = [[task defaults] integerForKey:SCMaxTargetMSKey] / (stimulusMS + interstimMS);

	lambda = log(2.0) / (meanTargetS - minTargetS + 0.5 / meanRateHz);
	maxTargetS = [[task defaults] integerForKey:SCMaxTargetMSKey] / 1000.0 - minTargetS + 1.0 / meanRateHz;
	catchTrialMaxPC = exp(-lambda * maxTargetS) *100.0;
	
	[[task defaults] setFloat:catchTrialMaxPC forKey:SCCatchTrialMaxPCKey];
	
	if ([[task defaults] floatForKey:SCCatchTrialPCKey] > catchTrialMaxPC)
		[[task defaults] setFloat:catchTrialMaxPC forKey:SCCatchTrialPCKey];
	
}

BehaviorSetting *getBehaviorSetting(void) {

	static BehaviorSetting behaviorSetting;
	
	behaviorSetting.blocks =  [[task defaults] integerForKey:SCBlockLimitKey];
	behaviorSetting.intertrialMS =  [[task defaults] integerForKey:SCIntertrialMSKey];
	behaviorSetting.acquireMS =  [[task defaults] integerForKey:SCAcquireMSKey];
	behaviorSetting.fixGraceMS = [[task defaults] integerForKey:SCFixGraceMSKey];
	behaviorSetting.fixateMS = [[task defaults] integerForKey:SCFixateMSKey];
	behaviorSetting.fixateJitterPC = [[task defaults] integerForKey:SCFixJitterPCKey];
	behaviorSetting.responseTimeMS = [[task defaults] integerForKey:SCRespTimeMSKey];
	behaviorSetting.tooFastMS = [[task defaults] integerForKey:SCTooFastMSKey];
	behaviorSetting.minSaccadeDurMS = [[task defaults] integerForKey:SCSaccadeTimeMSKey];
	behaviorSetting.breakPunishMS = [[task defaults] integerForKey:SCBreakPunishMSKey];
	behaviorSetting.rewardSchedule = [[task defaults] integerForKey:SCRewardScheduleKey];
	behaviorSetting.rewardMS = [[task defaults] integerForKey:SCRewardMSKey];
	behaviorSetting.fixWinWidthDeg = [[task defaults] floatForKey:SCFixWindowWidthDegKey];
	behaviorSetting.respWinWidthDeg = [[task defaults] floatForKey:SCRespWindowWidthDegKey];
	
	return &behaviorSetting;
}


StimSetting *getStimSetting(void) {

	static StimSetting stimSetting;
	
	stimSetting.stimDurationMS =  [[task defaults] integerForKey:SCStimDurationMSKey];
	stimSetting.stimDurJitterPC =  [[task defaults] integerForKey:SCStimJitterPCKey];
	stimSetting.interStimMS =  [[task defaults] integerForKey:SCInterstimMSKey];
	stimSetting.interStimJitterPC = [[task defaults] integerForKey:SCInterstimJitterPCKey];
	stimSetting.stimDistribution =  [[task defaults] integerForKey:SCStimDistributionKey];
	stimSetting.minTargetOnTimeMS = [[task defaults] integerForKey:SCMinTargetMSKey];
	stimSetting.meanTargetOnTimeMS = [[task defaults] integerForKey:SCMeanTargetMSKey];
	stimSetting.maxTargetOnTimeMS = [[task defaults] integerForKey:SCMaxTargetMSKey];
	stimSetting.changeScale =  [[task defaults] integerForKey:SCChangeScaleKey];
	stimSetting.orientationChanges =  [[task defaults] integerForKey:SCOrientationChangesKey];
	stimSetting.maxChangeDeg =  [[task defaults] floatForKey:SCMaxDirChangeDegKey];
	stimSetting.minChangeDeg =  [[task defaults] floatForKey:SCMinDirChangeDegKey];
	stimSetting.changeRemains =  [[task defaults] boolForKey:SCChangeRemainKey];
	
	return &stimSetting;
}



// used in randUnitInterval()
#define kIA					16807
#define kIM					2147483647
#define kAM					(1.0 / kIM)
#define kIQ					127773
#define kIR					2836
#define kNTAB				32
#define kNDIV				(1 + (kIM - 1) / kNTAB)
#define kEPS				1.2e-7
#define kRNMX				(1.0 - kEPS)

float randUnitInterval(long *idum) {

	int j;
	long k;
	static long iy = 0;
	static long iv[kNTAB];
	float temp;	
	
	if (*idum <= 0 || !iy) {
		if (-(*idum) < 1)
			*idum = 1;
		else *idum = -(*idum);
		
		for (j = kNTAB + 7; j >= 0; j--) {
			k = (*idum) / kIQ;
			*idum = kIA * (*idum - k * kIQ) - kIR * k;
			if (*idum < 0)
				*idum += kIM;
			if (j < kNTAB)
				iv[j] = *idum;		
		}
		iy = iv[0];	
	}
	k = (*idum) / kIQ;
	*idum = kIA * (*idum - k * kIQ) - kIR *k;
	
	if (*idum < 0)
		*idum += kIM;	
	j = iy / kNDIV;
	iy = iv[j];
	iv[j] = *idum;
	
	temp = kAM * iy;

	if (temp > kRNMX)
		return kRNMX;
	else
		return temp;
}
	

// Get the parameters from user defaults that control what trials are displayed in a block, and put them
// into a structure.

void updateBlockStatus(void)
{
	long index;
	NSArray *changeArray;
	NSDictionary *entryDict;
	
	blockStatus.changes = [[task defaults] integerForKey:SCOrientationChangesKey];
	blockStatus.instructTrials = [[task defaults] integerForKey:SCInstructionTrialsKey];
	blockStatus.blockLimit = [[task defaults] integerForKey:SCBlockLimitKey];
	changeArray = [[task defaults] arrayForKey:SCChangeArrayKey];
	for (index = 0; index < blockStatus.changes; index++) {
		entryDict = [changeArray objectAtIndex:index];
		(blockStatus.orientationChangeDeg)[index] = [[entryDict valueForKey:SCChangeKey] floatValue];
		blockStatus.validReps[index] = [[entryDict valueForKey:SCValidRepsKey] longValue];
		blockStatus.invalidReps[index] = [[entryDict valueForKey:SCInvalidRepsKey] longValue];
	}
}


