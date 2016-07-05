//
//  LLStandardDataEvents.m
//  Lablib
//
//  Created by John Maunsell on Sat May 31 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLStandardDataEvents.h"
#import "LLDisplays.h"
#import "LLEyeCalibrator.h"
#import "LLDataDeviceController.h"

// Definitation for the contents of Cocoa structures that might appear in data events

LLDataDef NSAffineTransformStructDataDef[] = {
	{@"CGFloat", @"m11", 1, offsetof(NSAffineTransformStruct, m11)},
	{@"CGFloat", @"m12", 1, offsetof(NSAffineTransformStruct, m12)},
	{@"CGFloat", @"m21", 1, offsetof(NSAffineTransformStruct, m21)},
	{@"CGFloat", @"m22", 1, offsetof(NSAffineTransformStruct, m22)},
	{@"CGFloat", @"tX", 1, offsetof(NSAffineTransformStruct, tX)},
	{@"CGFloat", @"tY", 1, offsetof(NSAffineTransformStruct, tY)},
	{nil},
};

LLDataDef NSPointDataDef[] = {
	{@"CGFloat", @"x", 1, offsetof(NSPoint, x)},
	{@"CGFloat", @"y", 1, offsetof(NSPoint, y)},
	{nil},
};

LLDataDef NSSizeDataDef[] = {
	{@"CGFloat", @"width", 1, offsetof(NSSize, width)},
	{@"CGFloat", @"height", 1, offsetof(NSSize, height)},
	{nil},
};

LLDataDef NSRectDataDef[] = {
	{@"struct", @"origin", 1, offsetof(NSRect, origin), sizeof(NSPoint), NSPointDataDef},
	{@"struct", @"size", 1, offsetof(NSRect, size), sizeof(NSSize), NSSizeDataDef},
	{nil},
};

// Definitiona of Lablib structures that might appear in data events

LLDataDef RGBDoubleDef[] = {
	{@"double", @"red", 1, offsetof(RGBDouble, red)},
	{@"double", @"green", 1, offsetof(RGBDouble, green)},
	{@"double", @"blue", 1, offsetof(RGBDouble, blue)},
	{nil},
};

LLDataDef ADDataDef[] = {
    {@"short",	@"channel", 1, offsetof(ADData, channel)},
    {@"short",	@"data", 1, offsetof(ADData, data)},
    {nil}};

LLDataDef dataParamDef[] = {
    {@"char",	@"dataName", sizeof(Str31), offsetof(DataParam, dataName)},
    {@"char",	@"deviceName", sizeof(Str31), offsetof(DataParam, deviceName)},
    {@"long",	@"channel", 1, offsetof(DataParam, channel)},
    {@"float",	@"timing", 1, offsetof(DataParam, timing)},
    {@"long",	@"type", 1, offsetof(DataParam, type)},
    {nil}};

LLDataDef displayParamDataDef[] = {
    {@"double",	@"frameRateHz", 1, offsetof(DisplayParam, frameRateHz)},
    {@"long",	@"pixelBits", 1, offsetof(DisplayParam, pixelBits)},
    {@"long",	@"widthPix", 1, offsetof(DisplayParam, widthPix)},
    {@"long",	@"heightPix", 1, offsetof(DisplayParam, heightPix)},
    {@"struct", @"CIEx", 1, offsetof(DisplayParam, CIEx), sizeof(RGBDouble), RGBDoubleDef},
    {@"struct", @"CIEy", 1, offsetof(DisplayParam, CIEy), sizeof(RGBDouble), RGBDoubleDef},
    {@"double",	@"distanceMM", 1, offsetof(DisplayParam, distanceMM)},
    {@"double",	@"widthMM", 1, offsetof(DisplayParam, widthMM)},
    {@"double",	@"heightMM", 1, offsetof(DisplayParam, heightMM)},
    {nil}};

LLDataDef eyeCalibrationDataDef[] = {
    {@"float",	@"offsetSizeDeg", 1, offsetof(LLEyeCalibrationData, offsetSizeDeg)},
    {@"struct", @"currentOffsetDeg", 1, offsetof(LLEyeCalibrationData, currentOffsetDeg), sizeof(NSPoint), NSPointDataDef},
    {@"struct", @"targetDeg", kLLEyeCalibratorOffsets, offsetof(LLEyeCalibrationData, targetDeg), sizeof(NSPoint), NSPointDataDef},
    {@"struct", @"actualUnits", kLLEyeCalibratorOffsets, offsetof(LLEyeCalibrationData, actualUnits), sizeof(NSPoint), NSPointDataDef},
    {@"struct", @"cal", 1, offsetof(LLEyeCalibrationData, calibration), sizeof(NSAffineTransformStruct), NSAffineTransformStructDataDef},
    {nil}};

LLDataDef fixWindowDataDef[] = {
    {@"long",	@"index", 1, offsetof(FixWindowData, index)},
    {@"struct", @"windowDeg", 1, offsetof(FixWindowData, windowDeg), sizeof(NSRect), NSRectDataDef},
    {@"struct", @"windowUnits", 1, offsetof(FixWindowData, windowUnits), sizeof(NSRect), NSRectDataDef},
    {nil}};
		
LLDataDef timestampDef[] = {
    {@"short",	@"channel", 1, offsetof(TimestampData, channel)},
    {@"long",	@"time", 1, offsetof(TimestampData, time)},
    {nil}};

//	event name				bytes in one data element		definition of data
//
//  definition of the data has the following field:
//	typeName, dataName, elements (for arrays), offsetBytes (in structs), elementBytes, contents (for structs), tags (for structs)

static EventDefinition standardEventsWithDataDefs[] = {
	{@"fileEnd",			0,						{@"no data"}},
	{@"trialStart",			sizeof(long),			{@"long"}},
	{@"trialEnd",			sizeof(long),			{@"long"}},
	{@"trialCertify",		sizeof(long),			{@"long"}},
	{@"spikeZero",			sizeof(long),			{@"long"}},
	{@"sampleZero",			sizeof(long),			{@"long"}},
	{@"spike",				sizeof(TimestampData),	{@"struct", @"spike", 1, 0, sizeof(TimestampData), timestampDef}},
	{@"spike0",				sizeof(long),			{@"long"}},
	{@"sample",				sizeof(ADData),			{@"struct", @"ADData", 1, 0, sizeof(ADData), ADDataDef}},
	{@"sample01",			2 * sizeof(short),		{@"short", @"sample01", 2}},
	{@"dataParam",			sizeof(DataParam),		{@"struct", @"dataParam", 1, 0, sizeof(DataParam), dataParamDef}},	
	{@"eyeData",			2 * sizeof(short),		{@"short", @"eyeData", -1, 0, sizeof(short)}},
	{@"eyePData",			sizeof(short),			{@"short", @"eyePData", -1, 0, sizeof(short)}},
	{@"eyeXData",			sizeof(short),			{@"short", @"eyeXData", -1, 0, sizeof(short)}},
	{@"eyeYData",			sizeof(short),			{@"short", @"eyeYData", -1, 0, sizeof(short)}},
	{@"eyeLXData",			sizeof(short),			{@"short", @"eyeLXData", -1, 0, sizeof(short)}},
	{@"eyeLYData",			sizeof(short),			{@"short", @"eyeLYData", -1, 0, sizeof(short)}},
	{@"eyeLPData",			sizeof(short),			{@"short", @"eyeLPData", -1, 0, sizeof(short)}},
	{@"eyeRXData",			sizeof(short),			{@"short", @"eyeRXData", -1, 0, sizeof(short)}},
	{@"eyeRYData",			sizeof(short),			{@"short", @"eyeRYData", -1, 0, sizeof(short)}},
	{@"eyeRPData",			sizeof(short),			{@"short", @"eyeRPData", -1, 0, sizeof(short)}},
	{@"spikeData",			sizeof(short),			{@"short", @"spikeData", -1, 0, sizeof(short)}},
	{@"VBLData",			sizeof(short),			{@"short", @"VBLData", -1, 0, sizeof(short)}},
	{@"stimulusOn",			sizeof(long),			{@"long"}},
	{@"stimulusOff",		sizeof(long),			{@"long"}},
	{@"eyeWindow",			sizeof(FixWindowData),	{@"struct", @"fixWindowData", 1, 0, sizeof(FixWindowData), 
                                                            fixWindowDataDef}},
	{@"eyeCalibration",		sizeof(LLEyeCalibrationData), {@"struct", @"eyeCalibrationData", 1, 0, 
                                                            sizeof(LLEyeCalibrationData), eyeCalibrationDataDef}},
	{@"eyeLeftCalibration",	sizeof(LLEyeCalibrationData), {@"struct", @"eyeLeftCalibrationData", 1, 0, 
                                                            sizeof(LLEyeCalibrationData), eyeCalibrationDataDef}},
	{@"eyeRightCalibration",sizeof(LLEyeCalibrationData), {@"struct", @"eyeRightCalibrationData", 1, 0, 
                                                            sizeof(LLEyeCalibrationData), eyeCalibrationDataDef}},
	{@"displayCalibration", sizeof(DisplayParam),	{@"struct", @"displayCalibration", 1, 0, 
                                                            sizeof(DisplayParam), displayParamDataDef}},
	{@"fixOn",				0,						{@"no data"}},
	{@"fixOff",				0,						{@"no data"}},
	{@"fixate",				0,						{@"no data"}},
	{@"leverDown",			0,						{@"no data"}},
	{@"blocked",			0,						{@"no data"}},
	{@"videoRetrace",		sizeof(long),			{@"long"}},
	{@"text",				sizeof(char),			{@"string", @"text", -1}}
};

static EventDef standardEvents[] = {
	{@"fileEnd",			0},
	{@"trialStart",			sizeof(long)},
	{@"trialEnd",			sizeof(long)},
	{@"trialCertify",		sizeof(long)},
	{@"spikeZero",			sizeof(long)},
	{@"sampleZero",			sizeof(long)},
	{@"spike",				sizeof(TimestampData)},
	{@"spike0",				sizeof(long)},
	{@"sample",				sizeof(ADData)},
	{@"sample01",			2 * sizeof(short)},
	{@"dataParam",			sizeof(DataParam)},
	{@"eyeData",			2 * sizeof(short)},
	{@"eyeXData",			sizeof(short)},
	{@"eyeYData",			sizeof(short)},
	{@"eyeLXData",			sizeof(short)},
    {@"eyeLYData",			sizeof(short)},
	{@"eyeLPData",			sizeof(short)},
	{@"eyeRXData",			sizeof(short)},
	{@"eyeRYData",			sizeof(short)},
	{@"eyeRPData",			sizeof(short)},
	{@"spikeData",			sizeof(short)},
	{@"VBLData",			sizeof(short)},
	{@"stimulusOn",			sizeof(long)},
	{@"stimulusOff",		sizeof(long)},
	{@"eyeWindow",			sizeof(FixWindowData)},
	{@"eyeCalibration",		sizeof(LLEyeCalibrationData)},
	{@"eyeLeftCalibration",	sizeof(LLEyeCalibrationData)},
	{@"eyeRightCalibration",sizeof(LLEyeCalibrationData)},
	{@"displayCalibration", sizeof(DisplayParam)},
	{@"fixOn",				0},
	{@"fixOff",				0},
	{@"fixate",				0},
	{@"leverDown",			0},
	{@"blocked",			0},
	{@"videoRetrace",		sizeof(long)},
	{@"text",				-1}
};

// Standard events with data definitions

static float eotColorValues[][kGuns] = {
    {0.0, 0.7, 0.0},		// green
    {0.9, 0.0, 0.0},		// red
    {0.6, 0.4, 0.2},		// brown
    {0.0, 0.0, 1.0},		// blue
    {0.5, 0.5, 0.5},		// gray
    {1.0, 0.5, 0.0},		// orange
    {0.7, 0.0, 0.7},		// purple
    {0.0, 0.0, 0.0},		// black
};

static NSString *eotNames[] = {@"Correct", @"Wrong", @"Failed", @"Broke", @"Ignored", @"Quit"};

@implementation LLStandardDataEvents

+ (long)count;
{
	return (sizeof(standardEvents) / sizeof(EventDef));
}

+ (long)countOfEventsWithDataDefs;
{
	return (sizeof(standardEventsWithDataDefs) / sizeof(EventDefinition));
}

// Colors for behavioral end of trial codes

+ (NSColor *)eotColor:(long)index;
{
	if (index >= sizeof(eotColorValues) / (sizeof(float) * kGuns)) {
		return [NSColor whiteColor];
	}
	return [NSColor colorWithDeviceRed:eotColorValues[index][0]  
					green:eotColorValues[index][1] 
					blue:eotColorValues[index][2] alpha:1.0];
}

+ (EventDef *)events {

	return standardEvents;
}

+ (EventDefinition *)eventsWithDataDefs;
{
	return standardEventsWithDataDefs;
}

+ (NSString *)trialEndName:(short)eotCode;
{
	if (eotCode < kEOTTypes) {
		return eotNames[eotCode];
	}
	else {
		return [NSString stringWithFormat:@"EOT %d", eotCode];
    }
}

@end
