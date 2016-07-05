/*
 *  TUN.h
 *  Tuning
 *
 *  Copyright (c) 2006. All rights reserved.
 *
 */

#ifdef MAIN
#define EXTERN
#else
#define EXTERN	extern 
#endif

#define kPI          		(atan(1) * 4)
#define k2PI         		(atan(1) * 4 * 2)
#define kRadiansPerDeg      (kPI / 180.0)
#define kDegPerRadian		(180.0 / kPI)
#define kMaxNameChar		32
#define kMaxSteps			32

// The following should be changed to be unique for each application

enum {kLinearSpacing = 0, kLogSpacing, kSpacingType};
enum {kGabor = 0, kRandomDots, kStimTypes};

typedef struct {
	char	stimTypeName[kMaxNameChar];
	char	testTypeName[kMaxNameChar];
	long	stimTypeIndex;
	long	testTypeIndex;				// test type
	long	spacingType;				// linear or log spacing
	long	steps;						// number of active stimulus levels
	float   maxValue;					// maximum stimulus value
	float   minValue;					// maximum stimulus value
	float	values[kMaxSteps];			// list of stimulus values
} TestParams;

typedef struct BlockStatus {
	long blockLimit;					// number of blocks before stopping
	long blocksDone;					// number of blocks completed
	long stimDoneThisBlock;				// number of stim completed in this block
} BlockStatus;

typedef struct StimDesc {
	long	stimOnFrame;
	long	stimOffFrame;
	long	stimTypeIndex;
	long	stimIndex;
	float	eccentricityDeg;
	float	polarAngleDeg;
	float	testValue;
} StimDesc;

typedef struct TrialDesc {
	long	stimPerTrial;
} TrialDesc;

#ifndef	NoGlobals

// Behavior settings dialog

extern NSString *TUNAcquireMSKey;
extern NSString *TUNBlockLimitKey;
extern NSString *TUNBreakPunishMSKey;
extern NSString *TUNFixateKey;
extern NSString *TUNFixGraceMSKey;
extern NSString *TUNFixWindowWidthDegKey;
extern NSString *TUNIntertrialMSKey;
extern NSString *TUNNumInstructTrialsKey;
extern NSString *TUNPreStimMSKey;
extern NSString *TUNRespTimeMSKey;
extern NSString *TUNRewardMSKey;
extern NSString *TUNStimPerTrialKey;
extern NSString *TUNDoSoundsKey;
extern NSString *TUNTooFastMSKey;

// Stimulus settings dialog

extern NSString *TUNInterstimMSKey;
extern NSString *TUNInterstimJitterPCKey;
extern NSString *TUNMaxValueKey;
extern NSString *TUNStimDurationMSKey;
extern NSString *TUNStimJitterPCKey;
extern NSString *TUNPreStimMSKey;

extern NSString *TUNCircularKey;
extern NSString *TUNStimNameKey;
extern NSString *TUNStimValuesKey;
extern NSString *TUNTestValuesKey;
extern NSString *TUNTestNameKey;
extern NSString *TUNTestSpacingTypeKey;
extern NSString *TUNTestStepsKey;
extern NSString *TUNMaxValueKey;
extern NSString *TUNMinValueKey;

extern NSString *TUNContrastPCKey;
extern NSString *TUNEccentricityDegKey;
extern NSString *TUNKdlPhiDegKey;
extern NSString *TUNKdlThetaDegKey;
extern NSString *TUNDirectionDegKey;
extern NSString *TUNPolarAngleDegKey;
extern NSString *TUNRadiusDegKey;
extern NSString *TUNSigmaDegKey;
extern NSString *TUNSpatialFreqCPDKey;
extern NSString *TUNSpatialPhaseDegKey;
extern NSString *TUNStimTypeIndexKey;
extern NSString *TUNSpeedDPSKey;
extern NSString *TUNTemporalFreqHzKey;

#import "TUNStimuli.h"

BlockStatus						blockStatus;
BOOL							resetFlag;
LLScheduleController			*scheduler;
long							stimDone[kMaxSteps];
TestParams						testParams;
TUNStimuli						*stimuli;

#endif

LLTaskPlugIn					*task;


