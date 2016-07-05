/*
 *  SC.h
 *  SpotChange
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
enum {kLinear = 0, kLogarithmic};
enum {kUniform = 0, kExponential};
enum {kAuto = 0, kManual};
enum {kRewardFixed = 0, kRewardVariable};
enum {kNullStim = 0, kValidStim, kTargetStim, kFrontPadding, kBackPadding};
enum {kMyEOTCorrect = 0, kMyEOTMissed, kMyEOTEarlyToValid, kMyEOTEarlyToInvalid, kMyEOTBroke, 
				kMyEOTIgnored, kMyEOTQuit, kMyEOTTypes};
enum {kTrialStartCode = 1, kFixOnCode, kFixateCode, kCueOnCode, kCueOffCode, kStimulusOnCode, kStimulusOffCode,
    kTargetOnCode, kSaccadeCode, kTrialEndCode};

#define		kMaxOriChanges			12

typedef struct {
	long	levels;				// number of active stimulus levels
	float   maxValue;			// maximum stimulus value (i.e., direction change in degree)
	float   minValue;			// minimum stimulus value
} StimParams;

typedef struct StimDesc {
	long	index;
	long	stimOnFrame;
	long	stimOffFrame;
	short	stim0Type;
	short	stim1Type;
	float	contrast0PC;
	float	contrast1PC;
	float	direction0Deg;
	float	direction1Deg;
	float	orientationChangeDeg;
} StimDesc;

typedef struct TrialDesc {
	BOOL	instructTrial;
	BOOL	validTrial;
	BOOL	catchTrial;
	long	attendLoc;
	long	correctLoc;
	long	numStim;
	long	targetIndex;				// index (count) of target in stimulus sequence
	long	targetOnTimeMS;				// time from first stimulus (start of stimlist) to the target
	long	orientationChangeIndex;
	float	orientationChangeDeg;
} TrialDesc;

typedef struct BlockStatus {
	long	changes;
	float	orientationChangeDeg[kMaxOriChanges];
	float	validReps[kMaxOriChanges];
	long	validRepsDone[kMaxOriChanges];
	float	invalidReps[kMaxOriChanges];
	long	invalidRepsDone[kMaxOriChanges];
	long	instructDone;			// number of instruction trials left to do
	long	instructTrials;			// number of instruction trials left to do
	long	sidesDone;				// number of sides (out of kLocations) done
	long	blockLimit;				// number of blocks before stopping
	long	blocksDone;				// number of blocks completed
} BlockStatus;

// put parameters set in the behavior controller

typedef struct BehaviorSetting {
	long	blocks;
	long	intertrialMS;
	long	acquireMS;
	long	fixGraceMS;
	long	fixateMS;
	long	fixateJitterPC;
	long	responseTimeMS;
	long	tooFastMS;
	long	minSaccadeDurMS;
	long	breakPunishMS;
	long	rewardSchedule;
	long	rewardMS;
	float	fixWinWidthDeg;
	float	respWinWidthDeg;
} BehaviorSetting;

// put parameters set in the Stimulus controller

typedef struct StimSetting {
	long	stimDurationMS;
	long	stimDurJitterPC;
	long	interStimMS;
	long	interStimJitterPC;
	long	stimLeadMS;
	float	stimSpeedHz;
	long	stimDistribution;
	long	minTargetOnTimeMS;
	long	meanTargetOnTimeMS;
	long	maxTargetOnTimeMS;
	float	eccentricityDeg;
	float	polarAngleDeg;
	float	driftDirectionDeg;
	float	contrastPC;
	short	numberOfSurrounds;
	long	changeScale;
	long	orientationChanges;
	float	maxChangeDeg;
	float	minChangeDeg;
	long	changeRemains;
} StimSetting;


#ifndef	NoGlobals

// Behavior settings dialog

extern NSString *SCAcquireMSKey;
extern NSString *SCBlockLimitKey;
extern NSString *SCBreakPunishMSKey;
extern NSString *SCCatchTrialPCKey;
extern NSString *SCCatchTrialMaxPCKey;
extern NSString *SCCueMSKey;
extern NSString *SCChageScaleKey;
extern NSString *SCDoSoundsKey;
extern NSString *SCFixateKey;
extern NSString *SCFixateMSKey;
extern NSString *SCFixGraceMSKey;
extern NSString *SCFixJitterPCKey;
extern NSString *SCFixWindowWidthDegKey;
extern NSString *SCIntertrialMSKey;
extern NSString *SCInstructionTrialsKey;
extern NSString *SCInvalidRewardFactorKey;
extern NSString *SCMaxTargetMSKey;
extern NSString *SCMinTargetMSKey;
extern NSString *SCMeanTargetMSKey;
extern NSString *SCNontargetContrastPCKey;
//extern NSString *SCNumInstructTrialsKey;
extern NSString *SCNumExtraInstructTrialsKey;
extern NSString *SCNumMistakesForExtraInstructionsKey;
extern NSString *SCRespSpotSizeDegKey;
extern NSString *SCRespTimeMSKey;
extern NSString *SCRespWindowWidthDegKey;
extern NSString *SCRewardMSKey;
extern NSString *SCRewardScheduleKey;
extern NSString *SCSaccadeTimeMSKey;
extern NSString *SCStimDistributionKey;
extern NSString *SCStimRepsPerBlockKey;
extern NSString *SCTooFastMSKey;
extern NSString *SCValidFATimePunishMSKey;
extern NSString *SCInvalidFATimePunishMSKey;

// Stimulus settings dialog

extern NSString *SCInterstimMSKey;
extern NSString *SCInterstimJitterPCKey;
extern NSString *SCStimDurationMSKey;
extern NSString *SCStimJitterPCKey;
extern NSString *SCChangeScaleKey;
extern NSString *SCOrientationChangesKey;
extern NSString *SCMaxDirChangeDegKey;
extern NSString *SCMinDirChangeDegKey;
extern NSString *SCChangeRemainKey;
extern NSString *SCChangeArrayKey;

extern NSString *SCDistContrastPCKey;
extern NSString *SCKdlPhiDegKey;
extern NSString *SCKdlThetaDegKey;
extern NSString *SCRadiusDegKey;
extern NSString *SCSeparationDegKey;
extern NSString *SCSpatialFreqCPDKey;
extern NSString *SCSpatialPhaseDegKey;
extern NSString *SCTemporalFreqHzKey;

extern NSString *SCChangeKey;
extern NSString *SCInvalidRepsKey;
extern NSString *SCValidRepsKey;
extern NSString *SCGabor1AlphaFactorKey;

long		argRand;

#import "SCStimuli.h"
//#import "SCDigitalOut.h"
@class SCDigitalOut;

long							attendLoc;
BlockStatus						blockStatus;
BehaviorSetting					behaviorSetting;
BOOL							brokeDuringStim;
SCDigitalOut					*digitalOut;
BOOL							resetFlag;
LLScheduleController			*scheduler;
SCStimuli						*stimuli;

#endif

LLTaskPlugIn					*task;


