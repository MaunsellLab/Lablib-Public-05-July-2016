//
//  LLSynthIODevice.h
//  Lablib
//
//  Created by John Maunsell on Fri Apr 18 2003.
//  Copyright (c) 2003 . All rights reserved.
//

#import "LLIODevice.h"
#import "LLEyeCalibrator.h"
//#import <Lablib/LLSynthIOSettings.h>
#import "LLSynthSaccade.h"

#define kLLDefaultM11					0.001
#define kLLDefaultM12					0.0
#define kLLDefaultM21					0.0
#define kLLDefaultM22					0.001
#define kLLDefaultTX					0.0
#define kLLDefaultTY					0.0
#define kLLSynthEyeBreakDefault			0.05
#define kLLSynthEyeIgnoreDefault		0.01
#define kLLSynthEyeIntervalDefault		225
#define kLLSynthEyeNoiseDefault			0.10
#define kLLSynthEyeXDefault				0
#define kLLSynthEyeYDefault				1
#define kLLSynthLeverBitDefault			0
#define kLLSynthLeverDownDefault		0.02
#define kLLSynthLeverIgnoreDefault		0.01
#define kLLSynthLeverLatencyDefault		250
#define kLLSynthLeverUpDefault			0.10
#define kLLSynthSpikesDefault			0x000c
#define kLLSynthSpikesRandomDefault		0
#define kLLSynthVBLPeriodDefault		100
#define kLLSynthVBLDefault				1

extern NSString *LLSynthEyeBreakKey;
extern NSString *LLSynthEyeIgnoreKey;
extern NSString *LLSynthEyeIntervalKey;
extern NSString *LLSynthEyeNoiseKey;
extern NSString *LLSynthEyeXKey;
extern NSString *LLSynthEyeYKey;
extern NSString *LLSynthLeverBitKey;
extern NSString *LLSynthLeverLatencyKey;
extern NSString *LLSynthLeverIgnoreKey;
extern NSString *LLSynthLeverDownKey;
extern NSString *LLSynthLeverUpKey;
extern NSString *LLSynthM11Key;
extern NSString *LLSynthM12Key;
extern NSString *LLSynthM21Key;
extern NSString *LLSynthM22Key;
extern NSString *LLSynthSpikesKey;
extern NSString *LLSynthSpikesRandomKey;
extern NSString *LLSynthTXKey;
extern NSString *LLSynthTYKey;
extern NSString *LLSynthVBLKey;
extern NSString *LLSynthVBLRateKey;

@interface LLSynthIODevice : NSObject <LLIODevice> {

@protected
    BOOL 				dataEnabled;
	NSUserDefaults		*defaults;
	NSAffineTransform	*degToUnits;
	unsigned short		digitalWord;
    LLEyeCalibrator 	*eyeCalibrator;
    NSPoint 			eyePosition;
    NSPoint				eyeTargetDeg;
    BOOL				eyeTargetPresent;
    double				lastLeverDownTimeS;
    double				lastLeverUpTimeS;
    double				lastSpikeTimeS;
 	long				lastSpontBreakCheckTimeS;
    double				lastSpontDownCheckTimeS;
    double				lastSpontUpCheckTimeS;
	double 				leverDownTimeS;
    double				leverUpTimeS;
    BOOL				leverIsDown;
    double				nextSaccadeTimeS;
    long				nextChannel;
    double				nextRateTimeS;
    double 				nextSampleTimeS;
    double				nextSpikeRateHz;
    double 				nextSpikeTimeS;
    double 				nextVBLTimeS;
	NSPoint				offsetDeg;
    BOOL				randomSpikes;
	LLSynthSaccade		*saccade;
    double 				samplePeriodMS;
    double				spikeRateHz;
    //	LLSynthIOSettings	*synthSettings;
	unsigned short		timestampBits;
	double				timestampRefS;
	double				timestampTickPerMS;
	NSAffineTransformStruct transform;
	short				VBLBit;
}

- (void)doLeverDown;
- (void)doLeverUp;
- (long)enabledSpikeChannels;
- (void)loadAffineTransform;
- (void)setEyeTargetOff;
- (void)setEyeTargetOn:(NSPoint)target;
- (void)setNextSaccadeTimeS:(double)nextTimeS;
- (void)setOffsetDeg:(NSPoint)newOffset;
- (void)setSpikeRateHz:(double)rate atTime:(double)changeTimeS;
- (BOOL)spikeData:(TimestampData *)pData;
- (void)spikePeriodic;
- (void)spikeRandom;
- (void)updateEyePosition;
- (BOOL)VBLData:(TimestampData *)pData;

@end
