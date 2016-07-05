/*
 *  VCAN.h
 *  V4CAN
 *
 *  Copyright (c) 2012. All rights reserved.
 *
 */

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
} StimDesc;

typedef struct TrialDesc {
	BOOL	catchTrial;
    BOOL    hasDistractors;
	BOOL	instructTrial;
    long    repeatCount;                // number of time this trial will be repeated -- repeats not tallied
	long	attendState;
	long	attendLoc;
	long	numStim;
	long	rewardMS;
    long    targetOnTimeMS;
	long	targetIndices[kStimLocs];    // stim index in trial (count) for the target/distractor at each location
	float	targetContrastChangePC[kStimLocs];	// current target/distractor change by location
} TrialDesc;

#ifndef	NoGlobals

// Behavior settings dialog

extern NSString *VCANAcquireMSKey;
extern NSString *VCANBlockLimitKey;
extern NSString *VCANBreakPunishMSKey;
extern NSString *VCANCatchTrialPCKey;
extern NSString *VCANCueMSKey;
extern NSString *VCANEyeFilterKey;
extern NSString *VCANDoVarRewardsKey;
extern NSString *VCANExtraRewardRightFactorKey;
extern NSString *VCANExtraDifficultStimRepsKey;
extern NSString *VCANFixateKey;
extern NSString *VCANFixGraceMSKey;
extern NSString *VCANFixWindowWidthDegKey;
extern NSString *VCANIntertrialMSKey;
extern NSString *VCANMaxTargetMSKey;
extern NSString *VCANMeanTargetMSKey;
extern NSString *VCANMinContrastChangeKey;
extern NSString *VCANNumInstructTrialsKey;
extern NSString *VCANNumCorrectStaircaseUpKey;
extern NSString *VCANNumExtraInstructTrialsKey ;
extern NSString *VCANNumMistakesForExtraInstructionsKey;
extern NSString *VCANNumRepsAfterIncorrectKey;
extern NSString *VCANPrecueMSKey;
extern NSString *VCANPreStimMSKey;
extern NSString *VCANMeanDistractorMSKey;
extern NSString *VCANRelDistContrastKey;
extern NSString *VCANRelDistContrastChangeKey;
extern NSString *VCANRespTimeMSKey;
extern NSString *VCANRespWindowWidthDegKey;
extern NSString *VCANRewardMSKey;
extern NSString *VCANSaccadeTimeMSKey;
extern NSString *VCANStartContrastPCKey;
extern NSString *VCANStepDownPCKey;
extern NSString *VCANStimRepsPerBlockKey;
extern NSString *VCANDoSoundsKey;
extern NSString *VCANTooFastMSKey;
extern NSString *VCANTrainingModeKey;
extern NSString *VCANVarRewardTCMSKey;
extern NSString *VCANVarRewardMaxMSKey;
extern NSString *VCANVarRewardMinMSKey;
extern NSString *VCANDoErrorCueKey;

// Quest

extern NSString *VCANQuestJitterPCKey;
extern NSString *VCANQuestGuessContrastPCKey;
extern NSString *VCANQuestCriterionKey;

// Stimulus settings dialog

extern NSString *VCANInterstimMSKey;
extern NSString *VCANInterstimJitterTauMSKey;
extern NSString *VCANStimDurationMSKey;
extern NSString *VCANStimJitterPCKey;
extern NSString *VCANStimLeadMSKey;

extern NSString *VCANEccentricityDegKey;
extern NSString *VCANKdlPhiDegKey;
extern NSString *VCANKdlThetaDegKey;
extern NSString *VCANDirectionDegKey;
extern NSString *VCANAngleRF0DegKey;
extern NSString *VCANAngleRF1DegKey;
extern NSString *VCANAngleRFOutDegKey;
extern NSString *VCANRadiusDegKey;
extern NSString *VCANSigmaDegKey;
extern NSString *VCANSpatialFreqCPDKey;
extern NSString *VCANSpatialPhaseDegKey;

@class VCANDigitalOut;
#import "VCANStimuli.h"
#import "VCANDiagnosticsController.h"

BlockStatus                 blockStatus;
BOOL                        brokeDuringStim;
VCANDiagnosticsController 	*diagnosticsController;
VCANDigitalOut              *digitalOut;
BOOL                        resetFlag;
LLNormDist                  *rewardAverage;
LLScheduleController        *scheduler;
long                        stimDone[kNumStates][kStimPerState];
VCANStimuli                 *stimuli;

#endif

NSColor                     *stateColors[kNumStates];
LLTaskPlugIn                *task;

