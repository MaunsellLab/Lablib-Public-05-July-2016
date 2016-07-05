//
//  LLEyeCalibrator.h
//  Lablib
//
//  Created by John Maunsell on Sun May 18 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLEyeWindow.h"
#import "LLSVDSolver.h"

#define kLLEyeCalibratorOffsets 		4

NSString *LLFixCalAzimuthDegKey;
NSString *LLFixCalElevationDegKey;
NSString *LLFixCalOffsetDegKey;
NSString *LLFixCorrectFactorKey;

typedef struct {
	float					offsetSizeDeg;							// size of the total fixation point offset
	NSPoint					currentOffsetDeg;						// total offset of the current test position
	NSPoint					targetDeg[kLLEyeCalibratorOffsets];		// total offset of each target position
	NSPoint					actualUnits[kLLEyeCalibratorOffsets];	// total offset of running average of positions
	NSAffineTransformStruct	calibration;							// current calibration structure
} LLEyeCalibrationData;

@interface LLEyeCalibrator : NSWindowController {

	NSAffineTransformStruct currentCalibration;				// calibration with offset
	NSAffineTransform		*degToUnits;
	LLEyeCalibrationData	data;
    NSString                *keyPrefix;
	NSAffineTransformStruct offsetCalibration;
	NSPoint					offsetDeg[kLLEyeCalibratorOffsets];
	long					offsetIndex;
	NSPoint					offsetUnits[kLLEyeCalibratorOffsets];
	BOOL					positionDone[kLLEyeCalibratorOffsets];
	long					positionsDone;
	LLSVDSolver				*SVDSolver;
	NSUserDefaults			*taskDefaults;
	NSAffineTransform		*unitsToDeg;	
}

+ (NSBezierPath *)bezierPathForCalibration:(LLEyeCalibrationData)cal;

- (NSAffineTransformStruct)calibration;
- (LLEyeCalibrationData *)calibrationData;
- (float)calibrationOffsetDeg;
- (NSPoint)calibrationOffsetPointDeg;
- (void)computeTransformFromOffsets;
- (NSPoint)degPointFromUnitPoint:(NSPoint)unitPoint;
- (void)initFinish;
- (id)initWithKeyPrefix:(NSString *)theKey;
- (NSString *)keyFor:(NSString *)keyType;
- (void)loadOffsets;
- (void)loadTransforms;
- (long)nextCalibrationPosition;
- (NSPoint)offsetDeg;
- (long)offsetIndex;
- (NSAffineTransformStruct)readCalibration;
- (void)readDefaults;
- (void)setDefaults:(NSUserDefaults *)newDefaults;
- (void)setCalibrationOffsetDeg:(float)newOffset;
- (void)setCalibrationPosition:(long)index;
- (void)setFixAzimuthDeg:(float)newAzimuthDeg elevationDeg:(float)newElevationDeg;
- (void)setKeyPrefix:(NSString *)newKey;
- (NSPoint)unitPointFromDegPoint:(NSPoint)degPoint;
- (NSRect)unitRectFromDegRect:(NSRect)rectDeg;
- (NSRect)unitRectFromEyeWindow:(LLEyeWindow *)eyeWindow;
- (NSSize)unitSizeFromDegSize:(NSSize)sizeDeg;
- (void)updateCalibration:(NSPoint)pointDeg;

- (IBAction)changeToDefaults:(id)sender;
- (IBAction)parametersChanged:(id)sender;

@end
