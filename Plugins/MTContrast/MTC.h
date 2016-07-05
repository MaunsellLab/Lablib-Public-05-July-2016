/*
 *  MTC.h
 *  MTContrast
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

// The following should be changed to be unique for each application

enum {kAttend0 = 0, kAttend1, kLocations};
enum {kNullStim = 0, kValidStim, kTargetStim, kFrontPadding, kBackPadding};

#define		kMaxContrasts			16

typedef struct {
	long	levels;				// number of active stimulus levels
	float   maxValue;			// maximum stimulus value
	float   factor;				// factor between values
} StimParams;

typedef struct BlockStatus {
	long attendLoc;					// currently attended location;
	long instructsDone;				// number of instructions completed this loc
	long presentationsPerLoc;		// number of stimulus presentations on each loc (contrasts * reps)
	long presentationsDoneThisLoc;	// number presentations completed, current loc, current block
	long locsPerBlock;				// number of locations (kLocations)
	long locsDoneThisBlock;			// number of locations completed, current block
	long blockLimit;				// number of blocks before stopping
	long blocksDone;				// number of blocks completed
} BlockStatus;

typedef struct StimDesc {
	long	attendLoc;
	long	stimOnFrame;
	long	stimOffFrame;
	short	type0;
	short	type1;
	short	contrastIndex;
	float	contrastPC;
	float	speed0DPS;
	float	speed1DPS;
	float	direction0Deg;
	float	direction1Deg;
} StimDesc;

typedef struct TrialDesc {
	BOOL	catchTrial;
	BOOL	instructTrial;
	long	attendLoc;
	long	numStim;
	long	targetIndex;
	long	distIndex;
	long	targetContrastIndex;
	float	targetContrastPC;
	float	stimulusSpeed;
	float	targetSpeed;
	float	direction0Deg;
	float	direction1Deg;
} TrialDesc;

#ifndef	NoGlobals

// Behavior settings dialog

extern NSString *MTCAcquireMSKey;
extern NSString *MTCBlockLimitKey;
extern NSString *MTCBreakPunishMSKey;
extern NSString *MTCCueMSKey;
extern NSString *MTCFixateKey;
extern NSString *MTCFixGraceMSKey;
extern NSString *MTCFixWindowWidthDegKey;
extern NSString *MTCIntertrialMSKey;
extern NSString *MTCMaxTargetMSKey;
extern NSString *MTCMeanTargetMSKey;
extern NSString *MTCNontargetContrastPCKey;
extern NSString *MTCNumInstructTrialsKey;
extern NSString *MTCPrecueMSKey;
extern NSString *MTCRelDistractorProbKey;
extern NSString *MTCRespSpotSizeDegKey;
extern NSString *MTCRespTimeMSKey;
extern NSString *MTCRespWindowWidthDegKey;
extern NSString *MTCRewardMSKey;
extern NSString *MTCSaccadeTimeMSKey;
extern NSString *MTCStimRepsPerBlockKey;
extern NSString *MTCStimulusSpeedDPSKey;
extern NSString *MTCDoSoundsKey;
extern NSString *MTCTargetSpeedDPSKey;
extern NSString *MTCTooFastMSKey;
extern NSString *MTCTriesKey;

// Stimulus settings dialog

extern NSString *MTCContrastFactorKey;
extern NSString *MTCContrastsKey;
extern NSString *MTCInterstimMSKey;
extern NSString *MTCInterstimJitterPCKey;
extern NSString *MTCMaxContrastKey;
extern NSString *MTCStimDurationMSKey;
extern NSString *MTCStimJitterPCKey;
extern NSString *MTCStimLeadMSKey;

extern NSString *MTCEccentricityDegKey;
extern NSString *MTCKdlPhiDegKey;
extern NSString *MTCKdlThetaDegKey;
extern NSString *MTCDirectionDegKey;
extern NSString *MTCPolarAngleDegKey;
extern NSString *MTCRadiusDegKey;
extern NSString *MTCSeparationDegKey;
extern NSString *MTCSigmaDegKey;
extern NSString *MTCSpatialFreqCPDKey;
extern NSString *MTCSpatialPhaseDegKey;
extern NSString *MTCTemporalFreqHzKey;

#import "MTCStimuli.h"

BlockStatus						blockStatus;
BOOL							brokeDuringStim;
BOOL							resetFlag;
LLScheduleController			*scheduler;
long							stimDone[kLocations][kMaxContrasts];
MTCStimuli						*stimuli;

#endif

LLTaskPlugIn					*task;


