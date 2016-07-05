//
//  LLBinocCalibrator.h
//  Lablib
//
//  Created by John Maunsell 
//  Copyright (c) 2012 All rights reserved.
//

#import "LLEyeCalibrator.h"

#ifndef kEyes
enum {kLeftEye, kRightEye};
#define kEyes   (kRightEye + 1)
#endif

#define kLLEyeCalibratorOffsets 		4

@interface LLBinocCalibrator : NSWindowController {

    LLEyeCalibrator         *calibrators[kEyes];
	NSAffineTransformStruct currentCalibration;				// calibration with offset
	LLEyeCalibrationData	data;
	NSAffineTransformStruct offsetCalibration;
	NSPoint					offsetDeg[kLLEyeCalibratorOffsets];
	long					offsetIndex;
	BOOL					positionDone[kLLEyeCalibratorOffsets];
	long					positionsDone;
	NSUserDefaults			*taskDefaults;
}

- (NSAffineTransformStruct)calibration;
- (NSAffineTransformStruct)calibrationForEye:(long)eyeIndex;
- (LLEyeCalibrationData *)calibrationData;
- (LLEyeCalibrationData *)calibrationDataForEye:(long)eyeIndex;
- (float)calibrationOffsetDeg;
- (NSPoint)calibrationOffsetPointDeg;
- (LLEyeCalibrator *)calibratorForEye:(long)eyeIndex;
- (NSPoint)degPointFromUnitPoint:(NSPoint)unitPoint;
- (NSPoint)degPointFromUnitPoint:(NSPoint)unitPoint forEye:(long)eyeIndex;
- (id)initWithKeyPrefix:(NSString *)prefix;
- (void)loadOffsets;
- (long)nextCalibrationPosition;
- (long)nextCalibrationPosition:(long)offsetIndex;
- (NSPoint)offsetDeg;
- (long)offsetIndex;
- (void)setDefaults:(NSUserDefaults *)newDefaults;
- (void)setCalibrationOffsetDeg:(float)newOffset;
- (void)setFixAzimuthDeg:(float)newAzimuthDeg elevationDeg:(float)newElevationDeg;
- (NSPoint)unitPointFromDegPoint:(NSPoint)degPoint;
- (NSPoint)unitPointFromDegPoint:(NSPoint)degPoint forEye:(long)eyeIndex;
- (NSRect)unitRectFromDegRect:(NSRect)rectDeg;
- (NSRect)unitRectFromDegRect:(NSRect)degRect forEye:(long)eyeIndex;
- (NSRect)unitRectFromEyeWindow:(LLEyeWindow *)eyeWindow;
- (NSRect)unitRectFromEyeWindow:(LLEyeWindow *)eyeWindow forEye:(long)eyeIndex;
- (NSSize)unitSizeFromDegSize:(NSSize)sizeDeg;
- (void)updateCalibration:(NSPoint)pointDeg;
- (void)updateCalibration:(NSPoint)pointDeg forEye:(long)eyeIndex;
- (void)updateLeftCalibration:(NSPoint)pointLDeg rightCalibration:(NSPoint)pointRDeg;

- (IBAction)changeToDefaults:(id)sender;
- (IBAction)parametersChanged:(id)sender;

@end
