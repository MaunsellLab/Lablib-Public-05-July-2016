//
//  LLLaserCalibrator.m
//  Lablib
//
//  Created by John Maunsell on 10/29/08.
//  Copyright 2008 Harvard Medical School. All rights reserved.
//

#import "LLLaserCalibrator.h"
#import "LLSystemUtil.h"

NSString *LLLaserCalibratorArrayKey = @"LLLaserCalibratorArray";
NSString *LLLaserCalibratorAttenuationKey = @"LLLaserCalibratorAttenuation";
NSString *voltageKey = @"voltage";
NSString *mWKey = @"mW";

@implementation LLLaserCalibrator

- (float)calibratedValueFor:(float)inputMW;
{
	long index;
	float outputVoltage, mW, voltage, lastVoltage, lastMW;
	NSMutableArray *calibrationArray;
	
	mW = [self maximumMW];
	if (mW < inputMW) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                      @"Requested value (%f) beyond calibrated range (%f).", inputMW, mW]];
//        NSRunAlertPanel(@"LLLaserCalibrator",  @"Requested value (%f) beyond calibrated range (%f).", @"OK",
//                        nil, nil, inputMW, mW);
		return -FLT_MAX;
	}
	[self getValuesForCalibrationIndex:0 voltagePtr:&lastVoltage mWPtr:&lastMW];
	if (lastMW > inputMW) {
        [LLSystemUtil runAlertPanelWithMessageText:[self className] informativeText:[NSString stringWithFormat:
                       @"Requested value (%f) below calibrated range (%f).", inputMW, lastMW]];
//		NSRunAlertPanel(@"LLLaserCalibrator",  @"Requested value (%f) below calibrated range (%f).", @"OK",
//						nil, nil, inputMW, lastMW);
		return -FLT_MAX;
	}
	calibrationArray = [NSMutableArray arrayWithArray:[taskDefaults arrayForKey:LLLaserCalibratorArrayKey]];
	for (index = 1, outputVoltage = 0; index < [calibrationArray count]; index++) {
		[self getValuesForCalibrationIndex:index voltagePtr:&voltage mWPtr:&mW];
		if (mW < inputMW) {
			lastMW = mW;
			lastVoltage = voltage;
		}
		else {
			outputVoltage = lastVoltage + (voltage - lastVoltage) *(inputMW - lastMW) / (mW - lastMW);		// linear interpolation
			break;
		}
	}
	return outputVoltage;	
}

- (void)dealloc;
{
	[sortArray release];
	[super dealloc];
}

- (void)doDialog;
{
	[NSApp runModalForWindow:[self window]];
	[[self window] orderOut:self];
}

// Return the voltage and mW for a calibration index value.  The mW value is adjusted by the probe attenuation

- (void)getValuesForCalibrationIndex:(long)index voltagePtr:(float *)pV mWPtr:(float *)pMW;
{
	NSDictionary *entry;
	NSMutableArray *calibrationArray;
	NSNumber *number;
	NSSortDescriptor *descriptor;
	NSArray *sortDescriptors;
	
	descriptor = [[[NSSortDescriptor alloc] initWithKey:mWKey ascending:YES] autorelease];
	sortDescriptors = [NSArray arrayWithObject:descriptor];
	calibrationArray = [NSMutableArray arrayWithArray:[taskDefaults arrayForKey:LLLaserCalibratorArrayKey]];
	[calibrationArray sortUsingDescriptors:sortDescriptors];
	entry = [calibrationArray objectAtIndex:index];
	number = [entry valueForKey:voltageKey];
	*pV = [number floatValue];
	number = [entry valueForKey:mWKey];
	*pMW = [number floatValue] * [taskDefaults floatForKey:LLLaserCalibratorAttenuationKey];
}

- (id)init;
{
	NSString *defaultsPath;
	NSDictionary *defaultsDict;
	NSSortDescriptor *sorter;
	
    if ((self = [super initWithWindowNibName:@"LLLaserCalibrator"]) != nil) {
        [self setWindowFrameAutosaveName:@"LLLaserCalibrator"];

// Set default calibration values, then try to read stored values
		
		defaultsPath = [[NSBundle bundleForClass:[LLLaserCalibrator class]] 
												pathForResource:@"LLLaserCalibrator" ofType:@"plist"];
		defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
		taskDefaults = [[NSUserDefaults standardUserDefaults] retain];
		[taskDefaults registerDefaults:defaultsDict];
		sorter = [[[NSSortDescriptor alloc] initWithKey:@"voltage" ascending:YES] autorelease];
		sortArray = [[NSArray alloc] initWithObjects:sorter, nil];
		[[self window] setDelegate:self];
    }
    return self;
}

- (IBAction)insertRow:(id)sender;
{
	long selectionIndex;
	NSMutableArray *calibrationArray;
	NSDictionary *entry;
	
	calibrationArray = [NSMutableArray arrayWithArray:[taskDefaults arrayForKey:LLLaserCalibratorArrayKey]];
	selectionIndex = [arrayController selectionIndex];
	if (selectionIndex == NSNotFound) {
		selectionIndex = [calibrationArray count] - 1;
		selectionIndex = MAX(selectionIndex, 0);
	}
	entry = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:1.0], @"voltage", 
					[NSNumber numberWithFloat:1.0], @"mW", nil];
	[calibrationArray insertObject:entry atIndex:selectionIndex];
	[taskDefaults setObject:calibrationArray forKey:LLLaserCalibratorArrayKey];
}

- (float)maximumMW;
{
	long index;
	float mW, voltage;
	NSMutableArray *calibrationArray;
	
	calibrationArray = [NSMutableArray arrayWithArray:[taskDefaults arrayForKey:LLLaserCalibratorArrayKey]];
	index = [calibrationArray count] - 1;
	[self getValuesForCalibrationIndex:index voltagePtr:&voltage mWPtr:&mW];
	return mW;
}

- (float)minimumMW;
{
	float mW, voltage;

	[self getValuesForCalibrationIndex:0 voltagePtr:&voltage mWPtr:&mW];
	return mW;
}

- (IBAction)ok:(id)sender;
{	
	[NSApp stopModal];
}

- (void)setDefaults:(NSUserDefaults *)newDefaults;
{
	[taskDefaults release];
	taskDefaults = newDefaults;
	[taskDefaults retain];
}

// When the user is done with the dialog, we make sure the data are in order by voltage.  The 
// table will display them however the user sorts the table, but we keep them in the order we need. 

- (BOOL)windowShouldClose:(NSNotification *)notification;
{
	long index;
	float value, lastValue;
	NSMutableArray *calibrationArray;
	NSArray *array;
	NSNumber *number;
	NSDictionary *entry;
	
	calibrationArray = [NSMutableArray arrayWithArray:[taskDefaults arrayForKey:LLLaserCalibratorArrayKey]];
	array = [calibrationArray sortedArrayUsingDescriptors:sortArray];
	[taskDefaults setObject:array forKey:LLLaserCalibratorArrayKey];
	for (index = 0, lastValue = LONG_MIN; index < [array count]; index++) {
		entry = [array objectAtIndex:index];
		number = [entry valueForKey:mWKey];
		value = [number floatValue];
		if (value < lastValue) {
            [LLSystemUtil runAlertPanelWithMessageText:[self className]
                                       informativeText:@"Calibration must be a monotonic function."];
//			NSRunAlertPanel(@"LLLaserCalibrator",  @"Calibration must be a monotonic function.", @"OK", nil, nil);
			return NO;
		}
		lastValue = value;
	}
	return YES;
}

@end
