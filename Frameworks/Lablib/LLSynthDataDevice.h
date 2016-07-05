//
//  LLSynthDataDevice.h
//  Lablib
//
//  Created by John Maunsell on Monday September 26, 2005.
//  Copyright (c) 2005. All rights reserved.
//

#import "LLDataDevice.h"
#import "LLEyeCalibrator.h"
#import "LLSynthDataSettings.h"
#import "LLSynthBinocSaccade.h"

#define kLLSynthADChannels				8
#define kLLSynthDigitalBits				16
#define kLLSynthSamplePeriodMS			5.0
#define kLLSynthTimestampPeriodMS		1

#ifndef kEyes
enum {kLeftEye, kRightEye};
#define kEyes   (kRightEye + 1)
#endif

extern NSString *LLSynthEyeBreakKey;
extern NSString *LLSynthEyeIgnoreKey;
extern NSString *LLSynthEyeIntervalKey;
extern NSString *LLSynthEyeNoiseKey;
extern NSString *LLSynthLeverBitKey;
extern NSString *LLSynthLeverLatencyKey;
extern NSString *LLSynthLeverIgnoreKey;
extern NSString *LLSynthLeverDownKey;
extern NSString *LLSynthLeverUpKey;
extern NSString *LLSynthLM11Key;
extern NSString *LLSynthLM12Key;
extern NSString *LLSynthLM21Key;
extern NSString *LLSynthLM22Key;
extern NSString *LLSynthRM11Key;
extern NSString *LLSynthRM12Key;
extern NSString *LLSynthRM21Key;
extern NSString *LLSynthRM22Key;
extern NSString *LLSynthSpikesKey;
extern NSString *LLSynthSpikesRandomKey;
extern NSString *LLSynthLTXKey;
extern NSString *LLSynthLTYKey;
extern NSString *LLSynthRTXKey;
extern NSString *LLSynthRTYKey;
extern NSString *LLSynthVBLKey;
extern NSString *LLSynthVBLRateKey;

@interface LLSynthDataDevice : LLDataDevice {

	NSUserDefaults		*defaults;
	NSAffineTransform	*degToUnits[kEyes];
    LLEyeCalibrator 	*eyeCalibrator;
    NSPoint 			eyePosition[kEyes];
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
    double				nextRateTimeS;
    double				nextSaccadeTimeS;
    double 				nextSampleTimeS;
    double				nextSpikeRateHz;
    double				nextSpikeTimeS;						// next time for periodic spike
    double 				nextVBLTimeS;						// next time for a vertical blank timestamp
	NSPoint				offsetDeg;
    BOOL				randomSpikes;
	LLSynthBinocSaccade	*saccade;
	NSMutableData		*sampleData[kLLSynthADChannels];
    double				spikeRateHz;
	LLSynthDataSettings	*synthSettings;
	NSMutableData		*timestampData[kLLSynthDigitalBits];
	double				timestampRefS;
	NSAffineTransformStruct transform[kEyes];
}

- (void)doLeverDown;
- (void)doLeverUp;
- (void)loadAffineTransforms;
- (void)setEyeTargetOff;
- (void)setEyeTargetOn:(NSPoint)target;
- (void)setNextSaccadeTimeS:(double)nextTimeS;
- (void)setOffsetDeg:(NSPoint)newOffset;
- (void)setSpikePeriodic;
- (void)setSpikeRandom;
- (void)setSpikeRateHz:(double)rate atTime:(double)changeTimeS;
- (void)spikeData;
- (void)updateEyePositions:(double)timeNowS;
- (void)VBLData;

@end
