/*
 *  VT.h
 *  Experiment
 *
 *  Created by John Maunsell on Sat Feb 01 2003.
 *  Copyright (c) 2003. All rights reserved.
 *
 */

// We need the following definition, even if the non-ITC18 version is being built

#import "VTStimuli.h"

#ifdef MAIN
#define EXTERN
#else
#define EXTERN	extern 
#endif

// The following should be changed to be unique for each application

enum {kLeverChannel = 0, kVBLChannel, kFirstSpikeChannel};
enum {kFirstInterval = 0, kSecondInterval};
enum {kVisualStimulus = 0, kElectricalStimulus, kStimTypes};

#define 	kLeverBit				(0x0001 << kLeverChannel)
#define		kRewardBit				0x0001
#define		kSpikeChannels			2						// One channels spikes, one channel stim pulses
#define		kSamplePeriodMS			5
#define		kTimestampTickMS		1

#define 	kMaxLevels				16
#define		kMaxHists				16

typedef struct {
	long	levels;				// number of active stimulus levels
	float   maxValue;			// maximum stimulus value
	float   factor;				// factor between values
} StimParams;

#ifndef	NoGlobals

// Behavior settings dialog

extern NSString *VTAcquireMSKey;
extern NSString *VTBlockLimitKey;
extern NSString *VTBreakPunishMSKey;
extern NSString *VTFixateKey;
extern NSString *VTFixGraceMSKey;
extern NSString *VTFixSpotSizeDegKey;
extern NSString *VTFixWindowWidthDegKey;
extern NSString *VTIntertrialMSKey;
extern NSString *VTNontargetContrastPCKey;
extern NSString *VTRespSpotSizeDegKey;
extern NSString *VTRespTimeMSKey;
extern NSString *VTRespWindowWidthDegKey;
extern NSString *VTRespWindow0AziKey;
extern NSString *VTRespWindow0EleKey;
extern NSString *VTRespWindow1AziKey;
extern NSString *VTRespWindow1EleKey;
extern NSString *VTRewardMSKey;
extern NSString *VTSaccadeTimeMSKey;
extern NSString *VTDoSoundsKey;
extern NSString *VTTooFastMSKey;
extern NSString *VTTriesKey;

// Stimulus settings dialog

extern NSString *VTStimTypeKey;

extern NSString *VTGapMSKey;
extern NSString *VTIntervalMSKey;
extern NSString *VTPostintervalMSKey;
extern NSString *VTPreintervalMSKey;

extern NSString *VTAzimuthDegKey;
extern NSString *VTElevationDegKey;
extern NSString *VTKdlPhiDegKey;
extern NSString *VTKdlThetaDegKey;
extern NSString *VTDirectionDegKey;
extern NSString *VTRadiusDegKey;
extern NSString *VTSigmaDegKey;
extern NSString *VTSpatialFreqCPDKey;
extern NSString *VTSpatialPhaseDegKey;
extern NSString *VTTemporalFreqHzKey;

extern NSString *VTContrastFactorKey;
extern NSString *VTContrastsKey;
extern NSString *VTMaxContrastKey;

extern NSString *VTCurrentsKey;
extern NSString *VTCurrentFactorKey;
extern NSString *VTDAChannelKey;
extern NSString *VTFrequencyHzKey;
extern NSString *VTGateBitKey;
extern NSString *VTDoGateKey;
extern NSString *VTPulseWidthUSKey;
extern NSString *VTMarkerPulseBitKey;
extern NSString *VTDoMarkerPulsesKey;
extern NSString *VTMaxCurrentKey;
extern NSString *VTUAPerVKey;

BOOL							brokeDuringStim;
BOOL							resetFlag;
LLScheduleController			*scheduler;
VTStimuli						*stimuli;
LLTrialBlock					*trialBlock;

#endif

LLTaskPlugIn					*task;


