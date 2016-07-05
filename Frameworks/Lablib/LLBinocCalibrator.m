//
//  LLBinocCalibrator.m
//  Lablib
//
//  Created by John Maunsell 2012
//  Copyright (c) 2012 All rights reserved.
//

#import "LLBinocCalibrator.h"

#define kDefaultCorrectFactor	0.025
#define kDefaultOffsetDeg		1.0
#define kDefaultM11				0.001
#define kDefaultM12				0.0
#define kDefaultM21				0.0
#define kDefaultM22				0.001
#define kDefaultTX				0.0
#define kDefaultTY				0.0

NSString *LLFixCalLM11Key = @"LLFixCalLM11";
NSString *LLFixCalLM12Key = @"LLFixCalLM12";
NSString *LLFixCalLM21Key = @"LLFixCalLM21";
NSString *LLFixCalLM22Key = @"LLFixCalLM22";
NSString *LLFixCalLTXKey = @"LLFixCalLTX";
NSString *LLFixCalLTYKey = @"LLFixCalLTY";
NSString *LLFixCalRM11Key = @"LLFixCalRM11";
NSString *LLFixCalRM12Key = @"LLFixCalRM12";
NSString *LLFixCalRM21Key = @"LLFixCalRM21";
NSString *LLFixCalRM22Key = @"LLFixCalRM22";
NSString *LLFixCalRTXKey = @"LLFixCalRTX";
NSString *LLFixCalRTYKey = @"LLFixCalRTY";

@implementation LLBinocCalibrator

- (NSAffineTransformStruct)calibration;
{
	return [calibrators[kLeftEye] calibration];
}

- (NSAffineTransformStruct)calibrationForEye:(long)eyeIndex;
{
	return [calibrators[eyeIndex] calibration];
}

- (LLEyeCalibrationData *)calibrationData;
{	
	return [calibrators[kLeftEye] calibrationData];
}

- (LLEyeCalibrationData *)calibrationDataForEye:(long)eyeIndex;
{	
	return [calibrators[eyeIndex] calibrationData];
}

// Return the current calibration offset, without the azimuth or elevation offset

- (float)calibrationOffsetDeg;
{
	return [taskDefaults floatForKey:LLFixCalOffsetDegKey];
}

- (NSPoint)calibrationOffsetPointDeg;
{
	return offsetDeg[offsetIndex];
}

- (LLEyeCalibrator *)calibratorForEye:(long)eyeIndex;
{
    return calibrators[eyeIndex];
}

- (IBAction)changeToDefaults:(id)sender;
{
	[calibrators[kLeftEye] changeToDefaults:self];
	[calibrators[kRightEye] changeToDefaults:self];
}

- (void)dealloc;
{
	[taskDefaults release];
    [calibrators[kLeftEye] release];
    [calibrators[kRightEye] release];
	[super dealloc];
}

- (NSPoint)degPointFromUnitPoint:(NSPoint)unitPoint;
{   
    return [calibrators[kLeftEye] degPointFromUnitPoint:unitPoint];
}

- (NSPoint)degPointFromUnitPoint:(NSPoint)unitPoint forEye:(long)eyeIndex;
{   
    return [calibrators[eyeIndex] degPointFromUnitPoint:unitPoint];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"%@:\n Left: %@\n Right %@", [self class],
		[calibrators[kLeftEye] description], [calibrators[kRightEye] description]];
}
	
- (id)init;
{
    long eyeIndex;
	NSString *defaultsPath;
	NSDictionary *defaultsDict;
    NSString *keyStrings[kEyes] = {@"LLFixCalL", @"LLFixCalR"};
	
    if ((self = [super initWithWindowNibName:@"LLBinocCalibrator"]) != nil) {
        
        // Set default calibration values, then try to read stored values
        
		defaultsPath = [[NSBundle bundleForClass:[LLEyeCalibrator class]] pathForResource:@"LLBinocCalibrator" 
                                                                                   ofType:@"plist"];
		defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
		taskDefaults = [[NSUserDefaults standardUserDefaults] retain];
		[taskDefaults registerDefaults:defaultsDict];
        
        [self loadOffsets];
        for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
            calibrators[eyeIndex] = [[LLEyeCalibrator alloc] initWithKeyPrefix:keyStrings[eyeIndex]];
        }
    }
    return self;
}

- (id)initWithKeyPrefix:(NSString *)prefix;
{
    long eyeIndex;
	NSString *defaultsPath, *extendedPrefix;
	NSDictionary *defaultsDict;
    NSString *extensionStrings[kEyes] = {@"L", @"R"};
	
    if ((self = [super initWithWindowNibName:@"LLBinocCalibrator"]) != nil) {
        
        // Set default calibration values, then try to read stored values
        
		defaultsPath = [[NSBundle bundleForClass:[LLEyeCalibrator class]] pathForResource:@"LLBinocCalibrator" 
                                                                                   ofType:@"plist"];
		defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
		taskDefaults = [[NSUserDefaults standardUserDefaults] retain];
		[taskDefaults registerDefaults:defaultsDict];
        
        [self loadOffsets];
        for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
            extendedPrefix = [NSString stringWithFormat:@"%@%@", prefix, extensionStrings[eyeIndex]];
            calibrators[eyeIndex] = [[LLEyeCalibrator alloc] initWithKeyPrefix:extendedPrefix];
        }
    }
    return self;
}

// Load the offset arrays that hold the positions that should be used for calibration. The offsets contain the 
// fixation point coordinates in units and degrees.  This requires us to initialize two fixed coordinate systems.  
// For degrees, we place the origin at the center of the screen.  Later on individual trials, we translate our 
// degrees coordinate system to place the origin at the current fixation point.

- (void)loadOffsets;
{
	long index;
	float halfCalOffsetDeg;				// half of the offset used for calibration, in degrees
	float azimuthDeg, elevationDeg;
	
	// Load the offset values.  The fixation azimuth and elevation offsets are added in here 
	
	azimuthDeg = [taskDefaults floatForKey:LLFixCalAzimuthDegKey];
	elevationDeg = [taskDefaults floatForKey:LLFixCalElevationDegKey];
	halfCalOffsetDeg = [taskDefaults floatForKey:LLFixCalOffsetDegKey] / 2.0;
    
	offsetIndex = -1;
	for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
		offsetDeg[index].x = ((index % 2) ? azimuthDeg + halfCalOffsetDeg : azimuthDeg - halfCalOffsetDeg);
		offsetDeg[index].y = ((index / 2) ? elevationDeg - halfCalOffsetDeg : elevationDeg + halfCalOffsetDeg);
	}	
}

- (long)nextCalibrationPosition;
{
	long index;
	
    // Choose a new offset to test
    
    if (positionsDone < kLLEyeCalibratorOffsets) {
        index = offsetIndex;
        do {
            index = (index + 1) % kLLEyeCalibratorOffsets;
        } while (positionDone[index]);
    }
    else {
        index = (rand() % kLLEyeCalibratorOffsets);
    }
    return [self nextCalibrationPosition:index];
}

- (long)nextCalibrationPosition:(long)newIndex;
{
    long posIndex;
	double halfOffsetDeg;
	
    // If we have completed a block of positions, we need to update the calibration before moving on
    
	if (positionsDone >= kLLEyeCalibratorOffsets) {
		halfOffsetDeg = [taskDefaults floatForKey:LLFixCalOffsetDegKey] / 2.0;
		if (halfOffsetDeg > 0) {								// avoid degenerate case
            [calibrators[kLeftEye] computeTransformFromOffsets];
            [calibrators[kRightEye] computeTransformFromOffsets];
		}
		for (posIndex = 0; posIndex < kLLEyeCalibratorOffsets; posIndex++) {
			positionDone[posIndex] = NO;
		}
		positionsDone = 0;
	}
	[calibrators[kLeftEye] setCalibrationPosition:newIndex];
	[calibrators[kRightEye] setCalibrationPosition:newIndex];
    offsetIndex = newIndex;
	return offsetIndex;
}

// Return the total offset, including both the calibration offset and the azimuth/elevation offset.  If the
// calibration offset is zero (or we haven't yet assigned a calibration offset), this is just the fix offset.
// If there is a fixation offset, then we return the value from offsetDeg[], which already includes the fix offset
// and the calibration offset.

- (NSPoint)offsetDeg;
{
	if ((offsetIndex < 0) || ([taskDefaults floatForKey:LLFixCalOffsetDegKey] <= 0)) {
		return NSMakePoint([taskDefaults floatForKey:LLFixCalAzimuthDegKey], 
					[taskDefaults floatForKey:LLFixCalElevationDegKey]);
	}
	else {
		return NSMakePoint(offsetDeg[offsetIndex].x, offsetDeg[offsetIndex].y);
	}
}

- (long)offsetIndex;
{
	return offsetIndex;
}

// The values in the dialog window have changed.  We reload the calibration transforms, and 
// reset the positions that we are testing.

- (IBAction)parametersChanged:(id)sender;
{
	long index;
	
	for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
		positionDone[index] = NO;
	}
	positionsDone = 0;
    [self loadOffsets];
	[calibrators[kLeftEye] parametersChanged:self];
	[calibrators[kRightEye] parametersChanged:self];
}

// set the size of the offset step that will be used for calibration
 
- (void)setCalibrationOffsetDeg:(float)newOffset;
{
	[taskDefaults setFloat:newOffset forKey:LLFixCalOffsetDegKey];
	[self parametersChanged:self];
}

- (void)setDefaults:(NSUserDefaults *)newDefaults;
{
	[taskDefaults release];
	taskDefaults = newDefaults;
	[taskDefaults retain];
	[calibrators[kLeftEye] setDefaults:newDefaults];
	[calibrators[kRightEye] setDefaults:newDefaults];
}

- (void)setFixAzimuthDeg:(float)newAzimuthDeg elevationDeg:(float)newElevationDeg;
{
	[taskDefaults setFloat:newAzimuthDeg forKey:LLFixCalAzimuthDegKey];
	[taskDefaults setFloat:newElevationDeg forKey:LLFixCalElevationDegKey];
	[self parametersChanged:self];
}

- (void)settingsChanged:(NSNotification *)notification;
{
	[calibrators[kLeftEye] readDefaults];
	[calibrators[kRightEye] readDefaults];
}

- (NSPoint)unitPointFromDegPoint:(NSPoint)degPoint;
{
	return [calibrators[kLeftEye] unitPointFromDegPoint:degPoint];
}

- (NSPoint)unitPointFromDegPoint:(NSPoint)degPoint forEye:(long)eyeIndex;
{
	return [calibrators[eyeIndex] unitPointFromDegPoint:degPoint];
}

- (NSRect)unitRectFromDegRect:(NSRect)degRect;
{
	return [calibrators[kLeftEye] unitRectFromDegRect:degRect];
}

- (NSRect)unitRectFromDegRect:(NSRect)degRect forEye:(long)eyeIndex;
{
	return [calibrators[eyeIndex] unitRectFromDegRect:degRect];
}

- (NSRect)unitRectFromEyeWindow:(LLEyeWindow *)eyeWindow;
{
	return [calibrators[kLeftEye] unitRectFromEyeWindow:eyeWindow];
}

- (NSRect)unitRectFromEyeWindow:(LLEyeWindow *)eyeWindow forEye:(long)eyeIndex;
{
	return [calibrators[eyeIndex] unitRectFromEyeWindow:eyeWindow];
}

- (NSSize)unitSizeFromDegSize:(NSSize)sizeDeg;
{
	return [calibrators[kLeftEye] unitSizeFromDegSize:sizeDeg];
}

- (NSSize)unitSizeFromDegSize:(NSSize)sizeDeg forEye:(long)eyeIndex;
{
	return [calibrators[eyeIndex] unitSizeFromDegSize:sizeDeg];
}

- (void)updateCalibration:(NSPoint)pointDeg;
{
    [calibrators[kLeftEye] updateCalibration:pointDeg];
//    [calibrators[kRightEye] updateCalibration:pointDeg];
	positionDone[offsetIndex] = YES;
	positionsDone++;
}

- (void)updateCalibration:(NSPoint)pointDeg forEye:(long)eyeIndex;
{
    [calibrators[eyeIndex] updateCalibration:pointDeg];
}

- (void)updateLeftCalibration:(NSPoint)pointLDeg rightCalibration:(NSPoint)pointRDeg;
{
    [calibrators[kLeftEye] updateCalibration:pointLDeg];
    [calibrators[kRightEye] updateCalibration:pointRDeg];
	positionDone[offsetIndex] = YES;
	positionsDone++;
}

@end
