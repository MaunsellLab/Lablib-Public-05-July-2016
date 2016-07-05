/*
 *  RF.h
 *  Experiment
 *
 *  Created by John Maunsell on Sat Feb 01 2003.
 *  Copyright (c) 2004. All rights reserved.
 *
 */

#import "RFMapStimuli.h"
#import "RFStateSystem.h"

enum {kLeverChannel = 0, kVBLChannel, kFirstSpikeChannel};
enum {kBarStimulus = 0, kGaborStimulus, kDotsStimulus, kPlaidStimulus, kStimTypes};
enum {kBehaviorAlways = 0, kBehaviorRunning, kBehaviorFixating};
enum {kAzimuthElevation = 0, kEccentricityAngle};

#define 	kLeverBit				(0x0001 << kLeverChannel)
#define		kRewardBit				0x0001
#define		kSpikeChannels			2
#define		kSamplePeriodMS			5
#define		kSamplePeriodS			(kSamplePeriodMS / 1000.0)
#define		kTimestampTickMS		1

#define 	kMaxLevels				8

typedef struct {
	long	levels;				// number of active stimulus levels
	float   maxValue;			// maximum stimulus value
	float   factor;				// factor between values
} StimParams;

typedef struct {
	float   azimuthDeg;	
	float   elevationDeg;
} StimCenter;

LLTaskPlugIn			*task;

#ifndef	NoGlobals

long					behaviorMode;
BOOL					resetFlag;
LLScheduleController	*scheduler;
RFMapStimuli			*stimuli;

// Preferences keys

extern NSString *RFTDoDataDirectoryKey;

extern NSString *RFAcquireMSKey;
extern NSString *RFDisplayUnitsKey;
extern NSString *RFDoFixateKey;
extern NSString *RFDoGridKey;
extern NSString *RFDoSoundsKey;
extern NSString *RFFixateMSKey;
extern NSString *RFFixWindowWidthDegKey;
extern NSString *RFFixSpotAzimuthDegKey;
extern NSString *RFFixSpotElevationDegKey;
extern NSString *RFFixSpotRadiusDegKey;
extern NSString *RFGridSpacingDegKey;
extern NSString *RFIntertrialMSKey;
extern NSString *RFRewardMSKey;

// Behavior setting keys

extern NSString *maxFixateMSKey;
extern NSString *RFMeanFixateMSKey;


// Stimulus setting keys

extern NSString *RFOrientationStepDegKey;
extern NSString *RFSizeFactorKey;
extern NSString *RFWidthFactorKey;

extern NSString *RFDisplayModeKey;
extern NSString *RFDoMouseGateKey;
extern NSString *RFStimTypeKey;

extern NSString *barContrastPCKey;
extern NSString *barKdlThetaDegKey;
extern NSString *barKdlPhiDegKey;
extern NSString *barLengthDegKey;
extern NSString *barOrientationDegKey;
extern NSString *barWidthDegKey;

extern NSString *gaborContrastKey;
extern NSString *gaborOrientationDegKey;
extern NSString *gaborKdlPhiDegKey;
extern NSString *gaborKdlThetaDegKey;
extern NSString *gaborRadiusDegKey;
extern NSString *gaborSigmaDegKey;
extern NSString *gaborSpatialFreqCPDKey;
extern NSString *gaborSpatialPhaseDegKey;
extern NSString *gaborTemporalFreqHzKey;
extern NSString *gaborTemporalPhaseDegKey;


#endif
