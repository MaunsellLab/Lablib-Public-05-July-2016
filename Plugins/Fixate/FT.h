/*
 *  FT.h
 *  Fixate
 *
 *  Created by John Maunsell on 12/25/04.
 *  Copyright 2004. All rights reserved.
 *
 */

#import "FTStimuli.h"

#define	kRewardBit				0x0001
enum {kLeverChannel = 0, kVBLChannel, kFirstSpikeChannel};

// ??? These should be removed

#define 	kLeverBit				(0x0001 << kLeverChannel)
#define		kRewardBit				0x0001
#define		kSpikeChannels			2						// One channels spikes, one channel stim pulses
#define		kSamplePeriodMS			5
#define		kSamplePeriodS			(kSamplePeriodMS / 1000.0)
#define		kTimestampTickMS		1
#define		kMaxHists				8

NSString *FTAcquireMSKey;
NSString *FTDoFixateKey;
NSString *FTDoSoundsKey;
NSString *FTFixateJitterPCKey;
NSString *FTFixateMSKey;
NSString *FTFixWindowWidthDegKey;
NSString *FTIntertrialMSKey;
NSString *FTRewardMSKey;
NSString *FTFixBackColorKey;
NSString *FTFixForeColorKey;
NSString *FTTaskModeKey;

LLTaskPlugIn				*task;
LLScheduleController		*scheduler;
FTStimuli					*stimuli;
