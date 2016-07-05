//
//  LLSynthIODevice.m
//  Lablib
//
//  Created by John Maunsell on Fri Apr 18 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLSynthIODevice.h"
#import "LLSynthIOSettings.h"
#import "LLSystemUtil.h"
#import "LLIODeviceController.h"
#import "LLSynthSaccade.h"

#define kLeverJitter 0.25
#define kUnitsPerDeg 500.0

@implementation LLSynthIODevice

- (BOOL)ADData:(short *)pArray {

	double fixNoiseDeg;
	NSSize fixNoiseEye;
	long channel;
    
    if (!dataEnabled || ([LLSystemUtil getTimeS] < nextSampleTimeS)) {
        return NO;
    }
	[self updateEyePosition];
	fixNoiseDeg = [defaults floatForKey:LLSynthEyeNoiseKey];
	fixNoiseEye = [degToUnits transformSize:NSMakeSize(fixNoiseDeg, fixNoiseDeg)];
	if (fixNoiseEye.width != 0) {
		fixNoiseEye.width = (rand() % (long)fixNoiseEye.width) - fixNoiseEye.width / 2;
	}
	if (fixNoiseEye.height != 0) {
		fixNoiseEye.height = (rand() % (long)fixNoiseEye.height) - fixNoiseEye.height / 2;
	}
	if ((channel = [defaults integerForKey:LLSynthEyeXKey]) >= 0) {
		pArray[channel] = MIN(SHRT_MAX, MAX(SHRT_MIN, eyePosition.x + fixNoiseEye.width));
	}
	if ((channel = [defaults integerForKey:LLSynthEyeYKey]) >= 0) {
		pArray[channel] = MIN(SHRT_MAX, MAX(SHRT_MIN, eyePosition.y + fixNoiseEye.height));
	}
    nextSampleTimeS += samplePeriodMS / 1000.0;
    return YES;
}

-  (BOOL)checkSpikeRateChange:(double)timeNowS {

    if (nextRateTimeS <= 0 || timeNowS < nextRateTimeS) {
        return NO;
    }
    spikeRateHz = nextSpikeRateHz;
    if (spikeRateHz <= 0) {
        nextSpikeTimeS = 1e100;
    }
    else {
        nextSpikeTimeS = nextRateTimeS + 1.0 / spikeRateHz;
    }
    nextRateTimeS = -1;
    return YES;
}

- (BOOL)canConfigure {

	return YES;
}

- (void)configure {

	if (synthSettings == nil) {
		synthSettings = [[LLSynthIOSettings alloc] init];
	}
	[synthSettings runPanel];
	[self loadAffineTransform];
}

- (BOOL)dataEnabled {

	return dataEnabled;
}

- (void)dealloc {

	if (synthSettings != nil) {
		[synthSettings release];
	}
	[eyeCalibrator release];
	[degToUnits release];
    [super dealloc];
}

- (unsigned short)digitalInputValues {

    double timeNow, noChangeProb, deltaS;
	long leverBit;
	double spontLeverUpPerS, spontLeverDownPerS;
    
	if ((leverBit = [defaults integerForKey:LLSynthLeverBitKey]) < 0) {
		return 0x0000;
	}
	leverBit = (0x1 << leverBit);
	timeNow = [LLSystemUtil getTimeS];

// Time to put the lever down

	if (leverDownTimeS > 0 && timeNow > leverDownTimeS && !(digitalWord & leverBit)) {
        digitalWord |= leverBit;
        lastLeverDownTimeS = leverDownTimeS;
        leverDownTimeS = lastSpontUpCheckTimeS = 0;
    }
    
// Time to put the lever up

	if (leverUpTimeS > 0 && timeNow > leverUpTimeS && (digitalWord & leverBit)) {
        digitalWord &= ~leverBit;
        lastLeverUpTimeS = leverUpTimeS;
        leverUpTimeS = lastSpontDownCheckTimeS = 0;
    }
    
// Spontaneous lever up?

    if (digitalWord & leverBit) {
		spontLeverUpPerS = [defaults floatForKey:LLSynthLeverUpKey];
        if (spontLeverUpPerS > 0 && lastSpontUpCheckTimeS > 0) {
            deltaS = timeNow - lastSpontUpCheckTimeS;
            noChangeProb = exp(deltaS * log(1.0 - spontLeverUpPerS)); 
            if (rand() % 1000 > noChangeProb * 1000.0) {
                digitalWord &= ~leverBit;
                lastLeverUpTimeS = lastSpontDownCheckTimeS = timeNow;
           }
       }
        lastSpontUpCheckTimeS = timeNow;
    }
    
// Spontaneous lever down?

    else {
		spontLeverDownPerS = [defaults floatForKey:LLSynthLeverDownKey];
        if (spontLeverDownPerS > 0 && lastSpontDownCheckTimeS > 0) {
            deltaS = timeNow - lastSpontDownCheckTimeS;
            noChangeProb = exp(deltaS * log(1.0 - spontLeverDownPerS)); 
            if (rand() % 1000 > noChangeProb * 1000.0) {
                digitalWord |= leverBit;
                lastLeverDownTimeS = lastSpontUpCheckTimeS = timeNow;
            }
        }
        lastSpontDownCheckTimeS = timeNow;
    }
	return digitalWord;
}

- (void)digitalOutputBitsOff:(unsigned short)bits {

}

- (void)digitalOutputBitsOn:(unsigned short)bits {

}

- (void)disableTimestampBits:(NSNumber *)bits {

	timestampBits &= ~[bits unsignedShortValue];
}

- (void)doLeverDown {

	float leverLatencyS, randomLatencyS;
	
    if ((rand() % 1000) > [defaults integerForKey:LLSynthLeverIgnoreKey] * 1000.0) {
		leverLatencyS = [defaults integerForKey:LLSynthLeverLatencyKey] / 1000.0;
		randomLatencyS = (leverLatencyS + 
					((rand() % 1000) * kLeverJitter * leverLatencyS) / 1000.0);
        leverDownTimeS = [LLSystemUtil getTimeS] + randomLatencyS;
        leverUpTimeS = 0;
    }
}

- (void)doLeverUp {

	float leverLatencyS, randomLatencyS;
	
    if ((rand() % 1000) > [defaults integerForKey:LLSynthLeverIgnoreKey] * 1000.0) {
 		leverLatencyS = [defaults integerForKey:LLSynthLeverLatencyKey] / 1000.0;
		randomLatencyS = (leverLatencyS + 
					((rand() % 1000) * kLeverJitter * leverLatencyS) / 1000.0);
       leverUpTimeS = [LLSystemUtil getTimeS] + randomLatencyS;
        leverDownTimeS = 0;
    }
}

- (long)enabledSpikeChannels {

	long index, enabledSpikes;
	
	for (index = enabledSpikes = 0; index < kDigitalBits; index++) {
		if ((timestampBits & (0x1 << index)) && (index != VBLBit)) {
			enabledSpikes++;
		}
	}
	return enabledSpikes;
}

- (void)enableTimestampBits:(NSNumber *)bits {

	timestampBits |= [bits unsignedShortValue];
}

- (id) init {

    NSMutableDictionary *defaultSettings;

    if ((self = [super init]) != nil) {
        spikeRateHz = 0.0;
		defaults = [NSUserDefaults standardUserDefaults];
        eyeCalibrator = [[LLEyeCalibrator alloc] init];
		degToUnits = [[NSAffineTransform alloc] init];

		defaultSettings = [NSMutableDictionary dictionary];
		
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLSynthEyeBreakDefault] forKey:LLSynthEyeBreakKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLSynthEyeIgnoreDefault] forKey:LLSynthEyeIgnoreKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLSynthEyeIntervalDefault] forKey:LLSynthEyeIntervalKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLSynthEyeNoiseDefault] forKey:LLSynthEyeNoiseKey];
		[defaultSettings setObject:[NSNumber numberWithInt:kLLSynthEyeXDefault] forKey:LLSynthEyeXKey];
		[defaultSettings setObject:[NSNumber numberWithInt:kLLSynthEyeYDefault] forKey:LLSynthEyeYKey];

		[defaultSettings setObject:[NSNumber numberWithFloat:kLLDefaultM11] forKey:LLSynthM11Key];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLDefaultM12] forKey:LLSynthM12Key];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLDefaultM21] forKey:LLSynthM21Key];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLDefaultM22] forKey:LLSynthM22Key];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLDefaultTX] forKey:LLSynthTXKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLDefaultTY] forKey:LLSynthTYKey];

		[defaultSettings setObject:[NSNumber numberWithInt:kLLSynthLeverBitDefault] forKey:LLSynthLeverBitKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLSynthLeverDownDefault] forKey:LLSynthLeverDownKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLSynthLeverIgnoreDefault] forKey:LLSynthLeverIgnoreKey];
		[defaultSettings setObject:[NSNumber numberWithInt:kLLSynthLeverLatencyDefault] forKey:LLSynthLeverLatencyKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLSynthLeverUpDefault] forKey:LLSynthLeverUpKey];

		[defaultSettings setObject:[NSNumber numberWithInt:kLLSynthSpikesDefault] forKey:LLSynthSpikesKey];
		[defaultSettings setObject:[NSNumber numberWithInt:kLLSynthSpikesRandomDefault] forKey:LLSynthSpikesRandomKey];
		[defaultSettings setObject:[NSNumber numberWithBool:kLLSynthVBLDefault] forKey:LLSynthVBLKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:kLLSynthVBLPeriodDefault] forKey:LLSynthVBLRateKey];

		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultSettings];
		
		[self loadAffineTransform];
    }
    return self;
}

// Load the NSAffineTransform with its transform.  The values are stored as unitsToDeg, for compatibility with
// the transform used for calibration.  But here was are going to use it only for degToUnits, so we invert it
// after it is loaded. 

- (void) loadAffineTransform {

	transform.m11 = [defaults floatForKey:LLSynthM11Key];
	transform.m12 = [defaults floatForKey:LLSynthM12Key];
	transform.m21 = [defaults floatForKey:LLSynthM21Key];
	transform.m22 = [defaults floatForKey:LLSynthM22Key];
	transform.tX = [defaults floatForKey:LLSynthTXKey];
	transform.tY = [defaults floatForKey:LLSynthTYKey];
	[degToUnits setTransformStruct:transform];
	[degToUnits invert];
}

- (NSString *)name {

	return @"Synthetic";
}

- (long)samplePeriodMS;
{
	return samplePeriodMS;
}

- (BOOL)setDataEnabled:(BOOL)state {

	BOOL previousState;
	
	previousState = dataEnabled;
	if (state && !dataEnabled) {
		dataEnabled = YES;
		nextSampleTimeS = nextSpikeTimeS = nextVBLTimeS = 
					lastSpikeTimeS = timestampRefS = [LLSystemUtil getTimeS];
	}
	else if (!state && dataEnabled) {
		dataEnabled = NO;
	}
	return previousState;
}

- (void)setEyeTargetOff {

    eyeTargetPresent = NO;
}

- (void)setEyeTargetOn:(NSPoint)target {

	if (rand() % 1000 > [defaults floatForKey:LLSynthEyeIgnoreKey] * 1000.0) {
        eyeTargetDeg = target;
        eyeTargetPresent = YES;
    }
}

- (void)setNextSaccadeTimeS:(double)nextTimeS;
{
	nextSaccadeTimeS = nextTimeS;
}

// The offsetDeg is applied after all transforms are made.  This is useful for keeping
// the synthetic eye positions aligned with different fixation offset.  

- (void)setOffsetDeg:(NSPoint)newOffset {

	offsetDeg = newOffset;
}

- (void)setSamplePeriodMS:(double)period {

		samplePeriodMS = period;
}

- (void)setSpikeRateHz:(double)rate atTime:(double)changeTimeS {

    nextSpikeRateHz = rate;
    nextRateTimeS = changeTimeS;
    nextSpikeTimeS = MIN(nextSpikeTimeS, changeTimeS + 1.0 / spikeRateHz);
}

- (void)setTimestampTickPerMS:(double)newTimestampTicksPerMS {

		timestampTickPerMS = newTimestampTicksPerMS;
}

- (BOOL)spikeData:(TimestampData *)pData {

    long inverseProb, spikeChannels;
    double timeNowS;
		
    timeNowS = [LLSystemUtil getTimeS];
    if (spikeRateHz == 0) {
        if (![self checkSpikeRateChange:timeNowS]) {
            return NO;
        }
    }

// For periodic spiking, return a spike for each channel each time we enter a new period 

    if (!randomSpikes) {
        if (timeNowS < nextSpikeTimeS) {		// if no spikes, check for rate change
            if (![self checkSpikeRateChange:timeNowS]) {
                return NO;
            }
        }
        if (timeNowS < nextSpikeTimeS) {		// check again after rate change
            return NO;
        }
        pData->channel = nextChannel;
        pData->time = (nextSpikeTimeS - timestampRefS) * 1000.0 * timestampTickPerMS;
		do {									// advance to next active !VBL bit
			nextChannel++; 
		} while (nextChannel < kDigitalBits && 
				((nextChannel == [defaults integerForKey:LLSynthVBLKey]) || 
					(timestampBits & (0x1 << nextChannel)) == 0));
        if (nextChannel >= kDigitalBits) {		// no more VBL bits, reset for next timestamp
            nextChannel = 0;
            nextSpikeTimeS += 1.0 / spikeRateHz;
            [self checkSpikeRateChange:nextSpikeTimeS];	// check whether spike time increment changes rate
        }
        return YES;
    }

// For random spikes, return a spike at random on a random channel

	spikeChannels = [self enabledSpikeChannels];
    inverseProb = 1000.0 * timestampTickPerMS / spikeRateHz / spikeChannels;
    do {
        lastSpikeTimeS += 0.001 / timestampTickPerMS;
        if ([self checkSpikeRateChange:lastSpikeTimeS]) {
            inverseProb = 1000.0 * timestampTickPerMS / spikeRateHz / spikeChannels;
        }
    } while ((lastSpikeTimeS < timeNowS) && (rand() % inverseProb) > 0);
    if (lastSpikeTimeS < timeNowS) {
        pData->channel = rand() % spikeChannels;
        pData->time = lastSpikeTimeS * 1000.0 * timestampTickPerMS;
        return YES;
    }
    return NO;
}

- (void) spikePeriodic {

    randomSpikes = NO;
}

- (void) spikeRandom {

    randomSpikes = YES;
}

- (BOOL)timestampData:(TimestampData *)pData {

    if (!dataEnabled) {							// do nothing if data is not enabled
        return NO;
    }
	if ([self spikeData:pData]) {
		return YES;
	}
	else {
		return [self VBLData:pData];
	}
}

- (long)timestampTickPerMS;
{
	return timestampTickPerMS;
}


- (void)updateEyePosition {

    BOOL fixate;
    double timeNowS, deltaS, noChangeProb, spontBreaksPerS, calibration;
	
    timeNowS = [LLSystemUtil getTimeS];
    
// If we are in the miadde of the saccade, do the next step of for the saccade
    
    if (saccade != nil) {
        eyePosition = [saccade nextPosition];
        if ([saccade done]) {
            [saccade release];
            saccade = nil;
            nextSaccadeTimeS = timeNowS + [defaults floatForKey:LLSynthEyeIntervalKey] / 1000.0;
        }
    }

// Otherwise, if it is time for a saccade, initialize one

    else if (timeNowS > nextSaccadeTimeS) {
        if (eyeTargetPresent) {
            fixate = YES;
			spontBreaksPerS =[defaults floatForKey:LLSynthEyeBreakKey];
            if (spontBreaksPerS > 0 && lastSpontBreakCheckTimeS > 0) {
                deltaS = timeNowS - lastSpontBreakCheckTimeS;
                noChangeProb = exp(deltaS * log(1.0 - spontBreaksPerS)); 
                fixate = (rand() % 1000 <= noChangeProb * 1000.0);
            }
            lastSpontBreakCheckTimeS = timeNowS;
        }
        else {
            fixate = NO;
        }
		calibration = [degToUnits transformSize:NSMakeSize(1.0, 1.0)].height;
        if (fixate) {
			saccade = [[LLSynthSaccade alloc] initFrom:(NSPoint)eyePosition
                        to:[degToUnits transformPoint:
						NSMakePoint(eyeTargetDeg.x + offsetDeg.x, eyeTargetDeg.y + offsetDeg.y)]
                        samplePerMS:samplePeriodMS unitsPerDeg:calibration];
        }
        else {
            saccade = [[LLSynthSaccade alloc] initFrom:(NSPoint)eyePosition
                        samplePerMS:samplePeriodMS unitsPerDeg:calibration];
            lastSpontBreakCheckTimeS = 0;
        }
        eyePosition = [saccade nextPosition];
    } 
}

- (BOOL)VBLData:(TimestampData *)pData {

    double VBLRateHz;
		
	VBLRateHz = [defaults floatForKey:LLSynthVBLRateKey];
    if (((VBLRateHz = [defaults floatForKey:LLSynthVBLRateKey]) == 0) ||
							([LLSystemUtil getTimeS] < nextVBLTimeS)) {
		return NO;
	}
	pData->channel = [defaults floatForKey:LLSynthVBLKey];
	pData->time = (nextVBLTimeS - timestampRefS) * 1000.0 * timestampTickPerMS;
	nextVBLTimeS += 1.0 / VBLRateHz;
	return YES;
}

@end
