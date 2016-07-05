/*
 *  LLPulseTrainDevice.h
 *  Lablib
 *  
 *  Protocol specifying required methods for a pulse train object
 *
 *  Created by John Maunsell on Aug 29 2008
 *  Copyright (c) 2008. All rights reserved.
 *
 */

#define kMaxChannels		16
enum {kVoltagePulses = 0, kCurrentPulses, kPulseTypes};

typedef struct {
	long	pulseType;
	float   amplitude;					// amplitude in uA or V.
	long	DAChannel;
	BOOL	doPulseMarkers;
	BOOL	doGate;
	long	durationMS;
	float   frequencyHZ;
	float   fullRangeV;
	long	gateBit;
	long	gatePorchMS;				// time that gates leads and trails stimulus
	BOOL	pulseBiphasic;
	long	pulseMarkerBit;
	long	pulseWidthUS;
	float   UAPerV;
} PulseTrainData;

@protocol LLPulseTrainDevice <NSObject>

- (NSData **)sampleData;
- (BOOL)samplesReady;
- (float)samplePeriodUS;
- (BOOL)setTrainArray:(NSArray *)trainArray;
- (BOOL)setTrainParameters:(PulseTrainData *)pTrain;
- (void)stimulate;

@end