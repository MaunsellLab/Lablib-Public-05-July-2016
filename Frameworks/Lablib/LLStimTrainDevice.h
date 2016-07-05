/*
 *  LLStimTrainDevice.h
 *  Lablib
 *  
 *  Protocol specifying required methods for an electrical stimulus train object
 *
 *  Created by John Maunsell on Fri Apr 18 2003.
 *  Copyright (c) 2003. All rights reserved.
 *
 */

#define kLLStimTrainDataEventDesc \
{{@"float", @"amplitudeUA", 1, offsetof(StimTrainData, amplitudeUA)},\
{@"long", @"DAChannel", 1, offsetof(StimTrainData, DAChannel)},\
{@"char", @"doPulseMarkers", 1, offsetof(StimTrainData, doPulseMarkers)},\
{@"char", @"doGate", 1, offsetof(StimTrainData, doGate)},\
{@"long", @"durationMS", 1, offsetof(StimTrainData, durationMS)},\
{@"float", @"frequencyHZ", 1, offsetof(StimTrainData, frequencyHZ)},\
{@"float", @"fullRangeV", 1, offsetof(StimTrainData, fullRangeV)},\
{@"long", @"gateBit", 1, offsetof(StimTrainData, gateBit)},\
{@"long", @"pulseMarkerBit", 1, offsetof(StimTrainData, pulseMarkerBit)},\
{@"long", @"pulseWidthUS", 1, offsetof(StimTrainData, pulseWidthUS)},\
{@"float", @"UAPerV", 1, offsetof(StimTrainData, UAPerV)},\
{nil}} 

typedef struct {
	float   amplitudeUA;
	long	DAChannel;
	BOOL	doPulseMarkers;
	BOOL	doGate;
	long	durationMS;
	float   frequencyHZ;
	float   fullRangeV;
	long	gateBit;
	long	pulseMarkerBit;
	long	pulseWidthUS;
	float   UAPerV;
} StimTrainData;

@protocol LLStimTrainDevice <NSObject>

- (BOOL)setTrainParameters:(StimTrainData *)pTrain;
- (void)stimulate;

@end