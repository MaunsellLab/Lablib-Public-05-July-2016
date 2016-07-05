//
//  LLMouseIODevice.m
//  Lablib
//
//  Created by John Maunsell on Thu Jun 05 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLMouseIODevice.h" 
#import "LLIODeviceController.h"
#import "LLIODeviceSettings.h"
#import "LLSystemUtil.h"
#import <Carbon/Carbon.h>				// for Button() 


@implementation LLMouseIODevice

- (BOOL)ADData:(short *)pArray {
	
	short c, xValue, yValue;
	unsigned short mouseXBits, mouseYBits;
	float mouseGain;
	double timeNowS;
	NSPoint mouseLoc;
	
	if (!dataEnabled) {
		return NO;
	}
	
// If a sample interval has not elapsed, there is nothing to do

	timeNowS = [LLSystemUtil getTimeS];
	if (timeNowS < nextSampleTimeS) {
		return NO;
	}

	mouseLoc = [NSEvent mouseLocation];
	mouseGain = [[NSUserDefaults standardUserDefaults] floatForKey:LLMouseGainKey];
	xValue = (mouseLoc.x - origin.x) * mouseGain;
	yValue = -(mouseLoc.y - origin.y) * mouseGain;
	
	mouseXBits = [[NSUserDefaults standardUserDefaults] integerForKey:LLMouseXBitsKey];
	mouseYBits = [[NSUserDefaults standardUserDefaults] integerForKey:LLMouseYBitsKey];
	for (c = 0; c < kADChannels; c++) {
		if (mouseXBits & (0x1 << c)) {
			pArray[c] = xValue;
		}
		else if (mouseYBits & (0x1 << c)) {
			pArray[c] = yValue;
		}
		else {
			pArray[c] = 0;
		}
	}
	
	nextSampleTimeS += samplePeriodMS / 1000.0;
	return YES;
}

- (BOOL)canConfigure {

	return YES;
}

- (void)configure {

	NSLog(@"Mouse Select Settings");
	if (mouseSettings == nil) {
		mouseSettings = [[LLMouseIOSettings alloc] init];
	}
	[mouseSettings runPanel];
}

- (void)dealloc {

	if (mouseSettings != nil) {
		[mouseSettings release];
	}
	[super dealloc];
}

- (unsigned short)digitalInputValues {

	if ([NSEvent pressedMouseButtons] & 1) {
		return [[NSUserDefaults standardUserDefaults] integerForKey:LLMouseButtonBitsKey];
	}
	else {
		return 0x0000;
	}
}

- (BOOL)dataEnabled {

	return dataEnabled;
}

- (void)digitalOutputBitsOff:(unsigned short)bits {

}

- (void)digitalOutputBitsOn:(unsigned short)bits {

}

- (void)disableTimestampBits:(NSNumber *)bits {

		timestampBits &= ~[bits unsignedShortValue];
}

- (void)enableTimestampBits:(NSNumber *)bits {

	timestampBits |= [bits unsignedShortValue];
}

- (NSString *)name {

	return @"Mouse";
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
		nextSampleTimeS = nextSpikeTimeS = timestampRefS = [LLSystemUtil getTimeS];
	}
	else if (!state && dataEnabled) {
		dataEnabled = timestampActive = NO;
	}
	return previousState;
}

- (void)setOrigin:(NSPoint)point {

	origin = point;
}

- (void)setSamplePeriodMS:(double)period {

		samplePeriodMS = period;
}

- (void)setTimestampTickPerMS:(double)newTimestampTicksPerMS {

		timestampTickPerMS = newTimestampTicksPerMS;
}

- (BOOL)timestampData:(TimestampData *)pData {

	unsigned short mouseButtonBits;
	BOOL validStamp = NO;
	
	
	if (!dataEnabled || timestampBits == 0) {	// not enabled, do nothing
		timestampActive = NO;
		return NO;
	}
	if (([NSEvent pressedMouseButtons] & 1) && !timestampActive) {				// new spike has arrived
		channel = 0;
		time = ([LLSystemUtil getTimeS] - timestampRefS) * 1000.0 * timestampTickPerMS;
		timestampActive = YES;
	}
	if (timestampActive && channel < kDigitalBits) {
		mouseButtonBits = [[NSUserDefaults standardUserDefaults] integerForKey:LLMouseButtonBitsKey];
		while (!(mouseButtonBits & (0x01 << channel)) && (channel < kDigitalBits)) {
			channel++;
		}
		if (channel < kDigitalBits) {
			pData->channel = channel++;
			pData->time = time;
			validStamp = YES;
		}
	}
	if (!([NSEvent pressedMouseButtons] & 1) && timestampActive && (channel >= kDigitalBits)) {
		timestampActive = NO;
	}
	return validStamp;
}

- (long)timestampTickPerMS;
{
	return timestampTickPerMS;
}
@end
