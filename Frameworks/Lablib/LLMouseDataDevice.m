//
//  LLMouseDataDevice.m
//  Lablib
//
//  Created by John Maunsell on Thu Jun 05 2003.
//  Copyright (c) 2005. All rights reserved.
//
// This device needs information about the state of the mouse buttons and the mouse location to work.
// It would be very difficult for it to pick up mouse events in a natural way, because it has no views
// of its own, and is miles away from the event stream.  For this reason, it has to depend on its
// owner (in the generic sense of the word "owner") to pass it information about the state of the 
// mouse buttons (it can get information about the location from NSEvent, but there is no Cocoa 
// equivalent of the old Carbon Button().   This should be done with setMouseState (which has been
// configured to permit information about multiple buttons, but we are only looking for the left
// mouse button here. NB that when the mouse is clicked over a button, that button absorbs the mouse
// up event, so it will not register in the event stream. The mouse down will be seen.

#import "LLMouseDataDevice.h" 
#import "LLDataDeviceController.h"
#import "LLSystemUtil.h"
#import "LLMouseDataSettings.h"

NSString *LLMouseButtonBitsKey = @"LLMouseButtonBits";
NSString *LLMouseGainKey = @"LLMouseGain";
NSString *LLMouseXBitsKey = @"LLMouseXBits";
NSString *LLMouseYBitsKey = @"LLMouseYBits";

static	LLMouseDataSettings	*mouseSettings;

@implementation LLMouseDataDevice

- (void)configure;
{
	if (mouseSettings == nil) {
		mouseSettings = [[LLMouseDataSettings alloc] init];
	}
	[mouseSettings runPanel];
}

- (void)dealloc;
{
	[mouseSettings release];
	[super dealloc];
}

- (unsigned short)digitalInputBits;
{
	if (mouseDown) {
		return [[NSUserDefaults standardUserDefaults] integerForKey:LLMouseButtonBitsKey];
	}
	else {
		return 0x0000;
	}
}

- (id)init;
{
	long channel;
	NSString *defaultsPath;
    NSDictionary *defaultsDict;

    if ((self = [super init]) != nil) {
		defaultsPath = [[NSBundle bundleForClass:[LLMouseDataDevice class]] 
							pathForResource:@"LLMouseDataDevice" ofType:@"plist"];
		defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
		for (channel = 0; channel < kLLMouseADChannels; channel++)  {
			[samplePeriodMS addObject:[NSNumber numberWithFloat:kLLMouseSamplePeriodMS]];
		}
		for (channel = 0; channel < kLLMouseDigitalBits; channel++)  {
			[timestampPeriodMS addObject:[NSNumber numberWithFloat:kLLMouseTimestampPeriodMS]];
		}
		devicePresent = YES;
    }
    return self;
}

- (NSString *)name;
{
	return @"Mouse";
}

// We have not made provisions for samples arriving at different rates on different channels,
// although that would not be a terrible chore.  We also only send back the x and y eye channels,
// although there is no reason we couldn't load the others (with zeros).

- (NSData **)sampleData;
{	
	short c, xValue, yValue;
	unsigned short mouseXBits, mouseYBits;
	float mouseGain;
	double timeNowS, samplePeriodS;
	NSPoint mouseLoc;
	NSMutableData *xData, *yData;
	
	if (!dataEnabled || sampleChannels == 0) {
		return nil;
	}
	timeNowS = [LLSystemUtil getTimeS];
	if (timeNowS < nextSampleTimeS) {
		return nil;
	}
	mouseLoc = [NSEvent mouseLocation];
	mouseGain = [[NSUserDefaults standardUserDefaults] floatForKey:LLMouseGainKey];
	xValue = (mouseLoc.x - origin.x) * mouseGain;
	yValue = (mouseLoc.y - origin.y) * mouseGain;
	xData = [NSMutableData dataWithLength:0];
	yData = [NSMutableData dataWithLength:0];
	samplePeriodS = [[samplePeriodMS objectAtIndex:0] floatValue] / 1000.0;
	while (nextSampleTimeS <= timeNowS) {
		[xData appendBytes:&xValue length:sizeof(short)];
		[yData appendBytes:&yValue length:sizeof(short)];
		nextSampleTimeS += samplePeriodS;
	}
	mouseXBits = [[NSUserDefaults standardUserDefaults] integerForKey:LLMouseXBitsKey];
	mouseYBits = [[NSUserDefaults standardUserDefaults] integerForKey:LLMouseYBitsKey];
	for (c = 0; c < kLLMouseADChannels; c++) {
		if (!(sampleChannels & (0x01 << c))) {
			sampleData[c] = nil;
		}
		else if (mouseXBits & (0x1 << c)) {
			sampleData[c] = xData;
		}
		else if (mouseYBits & (0x1 << c)) {
			sampleData[c] = yData;
		}
		else {
			sampleData[c] = nil;
		}
	}
	return sampleData;
}

- (void)setDataEnabled:(NSNumber *)state;
{
	if ([state boolValue] && !dataEnabled) {
		nextSampleTimeS = timestampRefS = [LLSystemUtil getTimeS];
	}
	dataEnabled = [state boolValue];
}

- (void)setMouseState:(long)state;
{
	mouseDown = (state == kLLLeftMouseDown);
}

- (void)setOrigin:(NSPoint)point;
{
	origin = point;
}

// We can change the sample period, but all sample channels must have the sample sample period

- (BOOL)setSamplePeriodMS:(float)newPeriodMS channel:(long)channel;
{
	if (channel >= [samplePeriodMS count]) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                @"Attempt to set sample period %ld of %lu for device %@",
                channel, (unsigned long)[samplePeriodMS count], [self name]]];
//		NSRunAlertPanel(@"LLDataDevice",
//				@"Attempt to set sample period %ld of %lu for device %@",
//				@"OK", nil, nil, channel, (unsigned long)[samplePeriodMS count], [self name]);
		exit(0);
	}
	[samplePeriodMS removeAllObjects];
	for (channel = 0; channel < kLLMouseADChannels; channel++) {
		[samplePeriodMS addObject:[NSNumber numberWithFloat:newPeriodMS]];
	}
	return YES;
}

- (NSData **)timestampData;
{
	unsigned short mouseButtonBits;
	long timeMS, channel, timeTicks;

	if (!dataEnabled || timestampChannels == 0) {		// no individual channels enabled
		return nil;
	}
	if (!mouseDown && buttonWasDown) {					// button just went up
		buttonWasDown = NO;
		return nil;
	}
	if (!mouseDown || buttonWasDown) {					// no change in button
		return nil;
	}

// A new button click has just arrived

	buttonWasDown = YES;
	timeMS = ([LLSystemUtil getTimeS] - timestampRefS) * 1000.0;
	mouseButtonBits = [[NSUserDefaults standardUserDefaults] integerForKey:LLMouseButtonBitsKey];
	for (channel = 0; channel < kLLMouseDigitalBits; channel++) {
		if (mouseButtonBits & (0x01 << channel)) {
			timeTicks = timeMS * (1.0 / [[timestampPeriodMS objectAtIndex:channel] floatValue]);
			timestampData[channel] = [NSMutableData dataWithBytes:&timeTicks length:sizeof(long)];
		}
		else {
			timestampData[channel] = nil;
		}
	}
	return timestampData;
}

@end
