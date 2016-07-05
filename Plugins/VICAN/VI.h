/*
 *  VI.h
 *  VICAN
 *
 *  Copyright (c) 2012. All rights reserved.
 *
 */

enum {kLinear = 0, kLogarithmic};


typedef enum {kInInAttIn0 = 0, kInInAttIn1, kInInAttFar0, kInInAttFar1,
                kInOutAttIn0, kInOutAttOut1, kInOutAttFar0, kInOutAttFar1, kNumStates} TaskState;
typedef enum {kNoStim = 0, kNullStim, kPrefStim, kRFStimTypes} RFStimTypes;
        enum {kInter0Stim = kRFStimTypes, kInter1Stim, kStimTypes};
typedef enum {kAttendPref = 0, kAttendNull, kAttendOut, kAttendTypes} AttendType;
typedef enum {kGabor0 = 0, kGabor1, kGaborFar0, kGaborFar1, kStimLocs} StimLoc;
typedef enum {kNilStim = 0, kValidStim, kTargetStim, kFrontPadding, kBackPadding, kPadding} StimListType;
typedef enum {kEOTEarly = kEOTTypes, kEOTDistractor, kExtendedEOTTypes} MyEOTs;

typedef enum {kTrialStartCode = 1, kFixateCode, kCueOnCode, kCueOffCode, kStimulusOnCode, kStimulusOffCode,
			kTargetOnCode, kSaccadeCode, kTrialEndCode} BlackRockCodes;
typedef enum {kTargetAttendLoc = 0, kTargetNear, kTargetFar} TrialTypes;

#define kMaxChanges     12
#define kStimPerState   (kRFStimTypes * kRFStimTypes)

typedef struct {
	long trials;
	float threshold;
	float confidenceInterval;
} QuestResults;

typedef struct BlockStatus {
	long attendState;				// which attention condition is current
	long attendLoc;					// currently attended location;
	long instructsDone;				// number of instructions completed this loc
	long presDoneThisState;			// number presentations completed, current loc, current block
	long presPerState;              // number of stimulus presentations on each loc (stimPerState * reps)
	long stimPerState;              // number of active contrasts in each state
	long statesPerBlock;			// number of locations (kStimLocs)
	long statesDoneThisBlock;		// number of locations completed, current block
	long doneStates[kNumStates];    // which states have been done
	long blockLimit;				// number of blocks before stopping
	long blocksDone;				// number of blocks completed
    long numChanges;                // number of alpha changes active
    float changes[kMaxChanges];     // values of alpha changes
} BlockStatus;

typedef struct StimDesc {               // Description of one presentation of stimuli at three locations
	long	attendState;                // TaskState
	long	attendLoc;                  // StimLoc: 0 in RF, 1 in or immediately outside, 2 far
    long    stimOnFrame;
	long	stimOffFrame;
	short	listTypes[kStimLocs];       // StimListType for each stimulus (null, valid, target, frontPad, backPad)
	long	stimTypes[kStimLocs];		// stimType assigned each stimulus location (P, N, or I)
	float	contrasts[kStimLocs];		// contrast value at each location
	float	directionsDeg[kStimLocs];	// direction at each location
	float	centerContrast[kStimLocs];	// contrast of center (which is the target
    float   targetOuterRadius;          // Outer radius of the target in deg
} StimDesc;

typedef struct TrialDesc {
	BOOL	catchTrial;
	BOOL	instructTrial;
    long    repeatCount;                // number of time this trial will be repeated -- repeats not tallied
	long	attendState;
	long	attendLoc;
	long	numStim;
	long	rewardMS;
    long    targetOnTimeMS;
    long    targetIndex;
    float	targetAlphaChange;	// current target/distractor change 
    long    targetAlphaChangeIndex; // index of the alpha change
    long    trialType; // 0=if target attended, 1=target Near RF, 2 = target Far RF
    long    targetPos; // 0 = RF0 ,1= RF1 or RFOut,2=FAR0 or 3=FAR1 or FAR OUT
} TrialDesc;

#ifndef	NoGlobals

// Behavior settings dialog

extern NSString *VIAcquireMSKey;
extern NSString *VIBlockLimitKey;
extern NSString *VIBreakPunishMSKey;
extern NSString *VICatchTrialPCKey;
extern NSString *VICueMSKey;
extern NSString *VIEyeFilterKey;
extern NSString *VIDoVarRewardsKey;
extern NSString *VIDistractorRewardFactorKey;
extern NSString *VIExtraDifficultStimRepsKey;
extern NSString *VIFixateKey;
extern NSString *VIFixGraceMSKey;
extern NSString *VIFixWindowWidthDegKey;
extern NSString *VIIntertrialMSKey;
extern NSString *VIMaxTargetMSKey;
extern NSString *VIMeanTargetMSKey;
extern NSString *VIMinContrastChangeKey;
extern NSString *VINumInstructTrialsKey;
extern NSString *VINumCorrectStaircaseUpKey;
extern NSString *VINumExtraInstructTrialsKey ;
extern NSString *VINumMistakesForExtraInstructionsKey;
extern NSString *VINumRepsAfterIncorrectKey;
extern NSString *VIPrecueMSKey;
extern NSString *VIPreStimMSKey;
extern NSString *VIMeanDistractorMSKey;
extern NSString *VIRelDistContrastKey;
extern NSString *VIRelDistContrastChangeKey;
extern NSString *VIRespTimeMSKey;
extern NSString *VIRespWindowWidthDegKey;
extern NSString *VIRewardMSKey;
extern NSString *VISaccadeTimeMSKey;
extern NSString *VIStartContrastPCKey;
extern NSString *VIStepDownPCKey;
extern NSString *VIStimRepsPerBlockKey;
extern NSString *VIDoSoundsKey;
extern NSString *VITooFastMSKey;
extern NSString *VITrainingModeKey;
extern NSString *VIVarRewardTCMSKey;
extern NSString *VIVarRewardMaxMSKey;
extern NSString *VIVarRewardMinMSKey;
extern NSString *VIDoErrorCueKey;

// Quest

extern NSString *VIQuestJitterPCKey;
extern NSString *VIQuestGuessContrastPCKey;
extern NSString *VIQuestCriterionKey;

// Stimulus settings dialog

extern NSString *VIAlphaChangeArrayKey;
extern NSString *VIAlphaChangesKey;
extern NSString *VIChangeKey;
extern NSString *VIMaxAlphaChangeKey;
extern NSString *VIMinAlphaChangeKey;
extern NSString *VIChangeAlphaScaleKey;
extern NSString *VIValidRepsKey;
extern NSString *VIInvalidNearRepsKey;
extern NSString *VIInvalidFarRepsKey;
extern NSString *VILoc2AlphaFactorKey;
extern NSString *VILoc3AlphaFactorKey;


extern NSString *VIInterstimMSKey;
extern NSString *VIInterstimJitterTauMSKey;
extern NSString *VIStimDurationMSKey;
extern NSString *VIStimJitterPCKey;
extern NSString *VIStimLeadMSKey;

extern NSString *VIEccentricityDegKey;
extern NSString *VIKdlPhiDegKey;
extern NSString *VIKdlThetaDegKey;
extern NSString *VIDirectionDegKey;
extern NSString *VIAngleRF0DegKey;
extern NSString *VIAngleRF1DegKey;
extern NSString *VIAngleRFOutDegKey;
extern NSString *VIRadiusDegKey;
extern NSString *VISigmaDegKey;
extern NSString *VISpatialFreqCPDKey;
extern NSString *VISpatialPhaseDegKey;

@class VIDigitalOut;
#import "VIStimuli.h"
#import "VIDiagnosticsController.h"

BlockStatus                 blockStatus;
BOOL                        brokeDuringStim;
VIDiagnosticsController 	*diagnosticsController;
VIDigitalOut              *digitalOut;
BOOL                        resetFlag;
LLNormDist                  *rewardAverage;
LLScheduleController        *scheduler;
long                        stimDone[kNumStates][kStimPerState];
VIStimuli                 *stimuli;

#endif

NSColor                     *stateColors[kNumStates];
LLTaskPlugIn                *task;

