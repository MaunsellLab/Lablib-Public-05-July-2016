//
//  LLSynthDataDevice.m
//  Lablib
//
//  Created by John Maunsell on Monday, September 26, 2005.
//  Copyright (c) 2005. All rights reserved.
//
/*

Although in principle we could have independent sampling rates and many channels,
this device is restricted to only two channels (x and y eye position) and they 
are yoked to a single sampling rate

*/
#import "LLSynthDataDevice.h"
#import "LLSynthDataSettings.h"
#import "LLSystemUtil.h"
#import "LLSynthSaccade.h"

enum {kXChannel = 0, kYChannel, kRXChannel, kRYChannel, kRPChannel, kLXChannel, kLYChannel, kLPChannel};

#define kLeverJitter 0.25
#define kUnitsPerDeg 500.0

NSString *LLSynthActiveSpikeChannelsKey = @"LLSynthActiveSpikeChannels";
NSString *LLSynthEyeBreakKey = @"LLSynthEyeBreak";
NSString *LLSynthEyeIgnoreKey = @"LLSynthEyeIgnore";
NSString *LLSynthEyeIntervalKey = @"LLSynthEyeInterval";
NSString *LLSynthEyeNoiseKey = @"LLSynthEyeNoise";
NSString *LLSynthEyeXKey = @"LLSynthEyeX";
NSString *LLSynthEyeYKey = @"LLSynthEyeY";
NSString *LLSynthLeverBitKey = @"LLSynthLeverBit";
NSString *LLSynthLeverLatencyKey = @"LLSynthLeverLatency";
NSString *LLSynthLeverIgnoreKey = @"LLSynthLeverIgnore";
NSString *LLSynthLeverDownKey = @"LLSynthLeverDown";
NSString *LLSynthLeverUpKey = @"LLSynthLeverUp";
NSString *LLSynthLM11Key = @"LLSynthLM11";
NSString *LLSynthLM12Key = @"LLSynthLM12";
NSString *LLSynthLM21Key = @"LLSynthLM21";
NSString *LLSynthLM22Key = @"LLSynthLM22";
NSString *LLSynthRM11Key = @"LLSynthRM11";
NSString *LLSynthRM12Key = @"LLSynthRM12";
NSString *LLSynthRM21Key = @"LLSynthRM21";
NSString *LLSynthRM22Key = @"LLSynthRM22";
NSString *LLSynthSpikesKey = @"LLSynthSpikes";
NSString *LLSynthSpikesRandomKey = @"LLSynthSpikesRandom";
NSString *LLSynthLTXKey = @"LLSynthLTX";
NSString *LLSynthLTYKey = @"LLSynthLTY";
NSString *LLSynthRTXKey = @"LLSynthRTX";
NSString *LLSynthRTYKey = @"LLSynthRTY";
NSString *LLSynthVBLKey = @"LLSynthVBL";
NSString *LLSynthVBLRateKey = @"LLSynthVBLRate";


@implementation LLSynthDataDevice

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

- (void)configure {

	if (synthSettings == nil) {
		synthSettings = [[LLSynthDataSettings alloc] init];
	}
	[synthSettings runPanel];
	[self loadAffineTransforms];
}

- (void)dealloc;
{
	[synthSettings release];
	[eyeCalibrator release];
	[degToUnits[kLeftEye] release];
	[degToUnits[kRightEye] release];
    [super dealloc];
}

- (unsigned short)digitalInputBits;
{
    double timeNow, noChangeProb, deltaS;
	long leverBit;
	double spontLeverUpPerS, spontLeverDownPerS;
    
	if ((leverBit = [defaults integerForKey:LLSynthLeverBitKey]) < 0) {
		return 0x0000;
	}
	leverBit = (0x1 << leverBit);
	timeNow = [LLSystemUtil getTimeS];

// Time to put the lever down

	if (leverDownTimeS > 0 && timeNow > leverDownTimeS && !(digitalInputBits & leverBit)) {
        digitalInputBits |= leverBit;
        lastLeverDownTimeS = leverDownTimeS;
        leverDownTimeS = lastSpontUpCheckTimeS = 0;
    }
    
// Time to put the lever up

	if (leverUpTimeS > 0 && timeNow > leverUpTimeS && (digitalInputBits & leverBit)) {
        digitalInputBits &= ~leverBit;
        lastLeverUpTimeS = leverUpTimeS;
        leverUpTimeS = lastSpontDownCheckTimeS = 0;
    }
    
// Spontaneous lever up?

    if (digitalInputBits & leverBit) {
		spontLeverUpPerS = [defaults floatForKey:LLSynthLeverUpKey];
        if (spontLeverUpPerS > 0 && lastSpontUpCheckTimeS > 0) {
            deltaS = timeNow - lastSpontUpCheckTimeS;
            noChangeProb = exp(deltaS * log(1.0 - spontLeverUpPerS)); 
            if (rand() % 1000 > noChangeProb * 1000.0) {
                digitalInputBits &= ~leverBit;
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
                digitalInputBits |= leverBit;
                lastLeverDownTimeS = lastSpontUpCheckTimeS = timeNow;
            }
        }
        lastSpontDownCheckTimeS = timeNow;
    }
	return digitalInputBits;
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

- (id)init;
{
	long channel;
	NSString *defaultsPath;
    NSDictionary *defaultsDict;

    if ((self = [super init]) != nil) {
        spikeRateHz = 0.0;
        eyeCalibrator = [[LLEyeCalibrator alloc] init];
		degToUnits[kLeftEye] = [[NSAffineTransform alloc] init];
		degToUnits[kRightEye] = [[NSAffineTransform alloc] init];
		defaultsPath = [[NSBundle bundleForClass:[LLSynthDataDevice class]] pathForResource:@"LLSynthDataDevice" ofType:@"plist"];
		defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
		defaults = [NSUserDefaults standardUserDefaults];
		[defaults registerDefaults:defaultsDict];
		[self loadAffineTransforms];
		for (channel = 0; channel < kLLSynthADChannels; channel++)  {
			[samplePeriodMS addObject:[NSNumber numberWithFloat:kLLSynthSamplePeriodMS]];
		}
		for (channel = 0; channel < kLLSynthDigitalBits; channel++)  {
			[timestampPeriodMS addObject:[NSNumber numberWithFloat:kLLSynthTimestampPeriodMS]];
		}
		devicePresent = YES;
    }
    return self;
}

// Load the NSAffineTransform with its transform.  The values are stored as unitsToDeg, for compatibility with
// the transform used for calibration.  But here was are going to use it only for degToUnits, so we invert it
// after it is loaded. 

- (void)loadAffineTransforms;
{
	transform[kLeftEye].m11 = [defaults floatForKey:LLSynthLM11Key];
	transform[kLeftEye].m12 = [defaults floatForKey:LLSynthLM12Key];
	transform[kLeftEye].m21 = [defaults floatForKey:LLSynthLM21Key];
	transform[kLeftEye].m22 = [defaults floatForKey:LLSynthLM22Key];
	transform[kLeftEye].tX = [defaults floatForKey:LLSynthLTXKey];
	transform[kLeftEye].tY = [defaults floatForKey:LLSynthLTYKey];
	[degToUnits[kLeftEye] setTransformStruct:transform[kLeftEye]];
	[degToUnits[kLeftEye] invert];
    
	transform[kRightEye].m11 = [defaults floatForKey:LLSynthRM11Key];
	transform[kRightEye].m12 = [defaults floatForKey:LLSynthRM12Key];
	transform[kRightEye].m21 = [defaults floatForKey:LLSynthRM21Key];
	transform[kRightEye].m22 = [defaults floatForKey:LLSynthRM22Key];
	transform[kRightEye].tX = [defaults floatForKey:LLSynthRTXKey];
	transform[kRightEye].tY = [defaults floatForKey:LLSynthRTYKey];
	[degToUnits[kRightEye] setTransformStruct:transform[kRightEye]];
	[degToUnits[kRightEye] invert];
}

- (NSString *)name
{
	return @"Synthetic";
}

- (void)setDataEnabled:(NSNumber *)state;
{
	if ([state boolValue] && !dataEnabled) {
		nextSampleTimeS = nextSpikeTimeS = nextVBLTimeS = 
					lastSpikeTimeS = timestampRefS = [LLSystemUtil getTimeS];
	}
	dataEnabled = [state boolValue];
}

// We only return data for two channels: x and y eye position.  They can be 
// linked to any of the synthetic AD channels.  The returned array contains
// one entry for each of the active channels

- (NSData **)sampleData;
{
	short sample, index, eyeIndex;
	double fixNoiseDeg, timeNowS;
	NSSize fixNoiseEye;
	DeviceADData theSample;							// struct for holding a sample
    NSMutableData *xData, *yData, *eyePData[kEyes], *eyeXData[kEyes], *eyeYData[kEyes];
    
    static short pupilValue = 3750.0;
    static short pupilNoise = 0;
    static long pupilCount = 0;
	
    if (!dataEnabled) {								// no data being collected
        return nil;
    }
	timeNowS = [LLSystemUtil getTimeS];

// Pick up all the data available from both channels and store them in NSData objects

	xData = [NSMutableData dataWithLength:0];
	yData = [NSMutableData dataWithLength:0];
    for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
        eyeXData[eyeIndex] = [NSMutableData dataWithLength:0];
        eyeYData[eyeIndex] = [NSMutableData dataWithLength:0];
        eyePData[eyeIndex] = [NSMutableData dataWithLength:0];
    }
	theSample.device = deviceIndex;
	while (timeNowS >= nextSampleTimeS) {
		[self updateEyePositions:nextSampleTimeS];
        fixNoiseDeg = [defaults floatForKey:LLSynthEyeNoiseKey];
        if ((++pupilCount % 100) == 0) {
            pupilNoise = (rand() % 2500);
        }
        for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
            fixNoiseEye = [degToUnits[eyeIndex] transformSize:NSMakeSize(fixNoiseDeg, fixNoiseDeg)];
            if (fixNoiseEye.width != 0) {
                fixNoiseEye.width = (rand() % (long)fixNoiseEye.width) - fixNoiseEye.width / 2;
            }
            if (fixNoiseEye.height != 0) {
                fixNoiseEye.height = (rand() % (long)fixNoiseEye.height) - fixNoiseEye.height / 2;
            }
            sample = MIN(SHRT_MAX, MAX(SHRT_MIN, eyePosition[eyeIndex].x + fixNoiseEye.width));
            if (eyeIndex == kLeftEye) {
                [xData appendBytes:&sample length:sizeof(sample)];
            }
            [eyeXData[eyeIndex] appendBytes:&sample length:sizeof(sample)];
            sample = MIN(SHRT_MAX, MAX(SHRT_MIN, eyePosition[eyeIndex].y + fixNoiseEye.height));
            if (eyeIndex == kLeftEye) {
                [yData appendBytes:&sample length:sizeof(sample)];
            }
            [eyeYData[eyeIndex] appendBytes:&sample length:sizeof(sample)];
            
            pupilValue += 0.02 * (2500 + pupilNoise - pupilValue);
            sample = MIN(SHRT_MAX, MAX(SHRT_MIN, 2500 + pupilValue));
            [eyePData[eyeIndex] appendBytes:&sample length:sizeof(pupilValue)];
        }
		nextSampleTimeS += [[samplePeriodMS objectAtIndex:0] floatValue] / 1000.0;
	}

// Bundle the data into an array.  If the channel is disabled, nil is returned.  If the 
// data length is zero, nil is returned.

	for (index = 0; index < kLLSynthADChannels; index++) {
		if (!(sampleChannels & (0x1 << index)) || [xData length] == 0) {
			sampleData[index] = nil;
			continue;
		}
        switch (index) {
            case kXChannel:
                sampleData[index] = xData;
                break;
            case kYChannel:
                sampleData[index] = yData;
                break;
            case kRXChannel:
                sampleData[index] = eyeXData[kRightEye];
                break;
            case kRYChannel:
                sampleData[index] = eyeYData[kRightEye];
                break;
            case kRPChannel:
                sampleData[index] = eyePData[kRightEye];
                break;
            case kLXChannel:
                sampleData[index] = eyeXData[kLeftEye];
                break;
            case kLYChannel:
                sampleData[index] = eyeYData[kLeftEye];
                break;
            case kLPChannel:
                sampleData[index] = eyePData[kLeftEye];
                break;
            default:
                break;
        }
	}
	return sampleData;
}

- (void)setEyeTargetOff;
{
    eyeTargetPresent = NO;
}

- (void)setEyeTargetOn:(NSPoint)target;
{
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

- (void)setOffsetDeg:(NSPoint)newOffset;
{
	offsetDeg = newOffset;
}

// We can change the sample period, but all sample channels must have the sample sample period

- (BOOL)setSamplePeriodMS:(float)newPeriodMS channel:(long)channel;
{
	if (channel >= [samplePeriodMS count]) {
        [LLSystemUtil runAlertPanelWithMessageText:@"LLDataDevice" informativeText:
        [NSString stringWithFormat:@"Attempt to set sample period %ld of %lu for device %@",
                        channel, (unsigned long)[samplePeriodMS count], [self name]]];
//        NSRunAlertPanel(@"LLDataDevice",
//                        @"Attempt to set sample period %ld of %lu for device %@",
//                        @"OK", nil, nil, channel, (unsigned long)[samplePeriodMS count], [self name]);
		exit(0);
	}
	[samplePeriodMS removeAllObjects];
	for (channel = 0; channel < kLLSynthADChannels; channel++) {
		[samplePeriodMS addObject:[NSNumber numberWithFloat:newPeriodMS]];
	}
	return YES;
}

- (void)setSpikePeriodic;
{
	[defaults setBool:NO forKey:LLSynthSpikesRandomKey];
}

- (void)setSpikeRandom;
{
	[defaults setBool:YES forKey:LLSynthSpikesRandomKey];
}

- (void)setSpikeRateHz:(double)rate atTime:(double)changeTimeS {

    nextSpikeRateHz = rate;
    nextRateTimeS = changeTimeS;
    nextSpikeTimeS = MIN(nextSpikeTimeS, changeTimeS + 1.0 / spikeRateHz);
}

- (void)spikeData;
{
	short timestamp;
    long  channel, theChannel, inverseProb, VBLBit, ticksPerMS, activeChannels, c;
	long channels[kLLSynthDigitalBits];
    double timeNowS, channelRateHz, lastChannelTimeS, channelNextRateTimeS;
	NSArray *activeSpikes;
		
    timeNowS = [LLSystemUtil getTimeS];
    if (spikeRateHz == 0) {
        if (![self checkSpikeRateChange:timeNowS]) {
            return;
        }
    }
	activeSpikes = [defaults arrayForKey:LLSynthActiveSpikeChannelsKey];
	if ([activeSpikes count] == 0) {
		return;
	}
	VBLBit = [defaults integerForKey:LLSynthVBLKey];

// Load an array with a list of all the spike channels that are both active and
// enabled (and not the VBL channel

	for (channel = activeChannels = 0; channel < kLLSynthDigitalBits; channel++) {
		if (channel != VBLBit && (timestampChannels & (0x1 << channel)) != 0) {
			for (c = 0; c < [activeSpikes count]; c++) {
				if ([[activeSpikes objectAtIndex:c] intValue] == channel) {
					channels[activeChannels++] = channel;
					timestampData[channel] = [NSMutableData dataWithLength:0];
					break;
				}
			}
		}
	}
	if (activeChannels == 0) {
		return;
	}
	
// For periodic spiking, return a spike for each active channel for each rate period 

    if (![defaults boolForKey:LLSynthSpikesRandomKey]) {
        if (timeNowS < nextSpikeTimeS) {		// if no spikes, check for rate change
            if (![self checkSpikeRateChange:timeNowS]) {
                return;
            }
        }
        if (timeNowS < nextSpikeTimeS) {		// check again after rate change
            return;
        }
		while (timeNowS >= nextSpikeTimeS) {
			for (channel = 0; channel < activeChannels; channel++) {
				theChannel = channels[channel];
				timestamp = (nextSpikeTimeS - timestampRefS) * 
								(1000.0 / [[timestampPeriodMS objectAtIndex:theChannel] floatValue]);
				[timestampData[theChannel] appendBytes:&timestamp length:sizeof(short)];
			}
			nextSpikeTimeS += 1.0 / spikeRateHz;
			[self checkSpikeRateChange:nextSpikeTimeS];	// check whether spike time increment changes rate
		}
    }

// For random spikes, spikes at random times at the appropriate rate

	else {
		for (channel = 0; channel < activeChannels; channel++) {
			theChannel = channels[channel];
			ticksPerMS = (1.0 / [[timestampPeriodMS objectAtIndex:theChannel] floatValue]);
			channelRateHz = spikeRateHz;
			channelNextRateTimeS = nextRateTimeS;
			inverseProb = 1000.0 * ticksPerMS / channelRateHz;
			for (lastChannelTimeS = lastSpikeTimeS; lastChannelTimeS < timeNowS; 
									lastChannelTimeS += 0.001 / ticksPerMS) {
				if (channelNextRateTimeS > 0 && lastChannelTimeS > channelNextRateTimeS) {		// check for rate change
					channelRateHz = nextSpikeRateHz;
					inverseProb = 1000.0 * ticksPerMS / channelRateHz;
					channelNextRateTimeS = -1;
				}
				if ((rand() % inverseProb) == 0) {
					timestamp = (lastChannelTimeS - timestampRefS) * 1000.0 * ticksPerMS;
					[timestampData[theChannel] appendBytes:&timestamp length:sizeof(short)];
				}
			}
		}
		lastSpikeTimeS = timeNowS;												// update spike time
		if (nextRateTimeS > 0 && nextSpikeTimeS > nextRateTimeS) {				// update spike rate
			spikeRateHz = nextSpikeRateHz;	
			nextRateTimeS = -1;
		}
	}
}

- (NSData **)timestampData;
{
	long channel;
	
    if (!dataEnabled) {							// do nothing if data is not enabled
        return nil;
    }
	if (timestampChannels == 0) {
		nextSpikeTimeS = lastSpikeTimeS = nextVBLTimeS = [LLSystemUtil getTimeS];
		return nil;
	}
	for (channel = 0; channel < kLLSynthDigitalBits; channel++) {
		timestampData[channel] = nil;
	}
	[self spikeData];
	[self VBLData];
	return timestampData;
}

- (void)updateEyePositions:(double)timeNowS;
{
    long eyeIndex;
    BOOL fixate;
    NSPoint eyePositionDeg[kEyes];
	float eyeSamplePeriodMS;
    double deltaS, noChangeProb, spontBreaksPerS;
	    
// If we are in the middle of the saccade, do the next step of for the saccade
    
    if (saccade != nil) {
        [saccade nextPositions:eyePosition];
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
        eyeSamplePeriodMS = [[samplePeriodMS objectAtIndex:0] floatValue];
        for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
            [degToUnits[eyeIndex] invert];
            eyePositionDeg[eyeIndex] = [degToUnits[eyeIndex] transformPoint:eyePosition[eyeIndex]];
            [degToUnits[eyeIndex] invert];
        }
        if (fixate) {
            saccade = [[LLSynthBinocSaccade alloc] initFrom:eyePositionDeg
                        to:NSMakePoint(eyeTargetDeg.x + offsetDeg.x, eyeTargetDeg.y + offsetDeg.y)
                        degToUnits:degToUnits samplePerMS:eyeSamplePeriodMS];
        }
        else {
            saccade = [[LLSynthBinocSaccade alloc] initFrom:eyePositionDeg
                        degToUnits:degToUnits samplePerMS:eyeSamplePeriodMS];
            lastSpontBreakCheckTimeS = 0;
        }
        [saccade nextPositions:eyePosition];
    } 
}

- (void)VBLData;
{
	short timestamp, VBLChannel;
	long ticksPerS;
    float VBLRateHz;
	double timeNow;
		
	VBLRateHz = [defaults floatForKey:LLSynthVBLRateKey];
    if (VBLRateHz == 0) {
		return;
	}
	timeNow = [LLSystemUtil getTimeS];
	if (timeNow < nextVBLTimeS) {
		return;
	}
	VBLChannel = [defaults integerForKey:LLSynthVBLKey];
	if ((timestampChannels & (0x1 << VBLChannel)) == 0) {
		return;
	}
	ticksPerS = (1000.0 / [[timestampPeriodMS objectAtIndex:VBLChannel] longValue]);
	timestampData[VBLChannel] = [NSMutableData dataWithLength:0];
	while (timeNow >= nextVBLTimeS) {
		timestamp = (nextVBLTimeS - timestampRefS) * ticksPerS;
		[timestampData[VBLChannel] appendBytes:&timestamp length:sizeof(short)];
		nextVBLTimeS += 1.0 / VBLRateHz;
	}
}

@end
