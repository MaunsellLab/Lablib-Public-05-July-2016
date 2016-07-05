//
//  LLEyeCalibrator.m
//  Lablib
//
//  Created by John Maunsell on Sun May 18 2003.
//  Copyright (c) 2006. All rights reserved.
//

#import "LLEyeCalibrator.h"
#import "LLSettingsController.h"

#define kCircleRadiusDeg		0.15
#define kCrossArmDeg			0.25
#define kDefaultScaleFactor		0.001
#define kLineWidthDeg			0.02

#define kDefaultCorrectFactor	0.025
#define kDefaultOffsetDeg		1.0
#define kDefaultM11				0.001
#define kDefaultM12				0.0
#define kDefaultM21				0.0
#define kDefaultM22				0.001
#define kDefaultTX				0.0
#define kDefaultTY				0.0

NSString *LLFixCalAzimuthDegKey = @"LLFixCalAzimuthDeg";
NSString *LLFixCalElevationDegKey = @"LLFixCalElevationDeg";
NSString *LLFixCalOffsetDegKey = @"LLFixCalOffsetDeg";
NSString *LLFixCorrectFactorKey = @"LLFixCorrectFactor";

@implementation LLEyeCalibrator

// Draw bars to show the current calibration.  We construct a parallogram that reflect
// the X and Y scaling of where the actually fixation points are (when plotted in  
// isotropic degree space).

+ (NSBezierPath *)bezierPathForCalibration:(LLEyeCalibrationData)cal;
{
	long index;
	float factor, xSum, ySum;
	NSPoint xVector, yVector, actualDeg;
	NSSize xVectorSize, yVectorSize;
	NSPoint c, a;
 	NSAffineTransform *unitsToDeg, *degToUnits;
	NSBezierPath *calBezierPath;
	
	if (cal.offsetSizeDeg == 0) {
		return nil;
	}
	unitsToDeg = [[NSAffineTransform alloc] init];
	degToUnits = [[NSAffineTransform alloc] init];
    
    if (cal.calibration.m11 * cal.calibration.m22 - cal.calibration.m12 * cal.calibration.m21 == 0) {
        NSLog(@"LLEyeCalibrator +bezierPathForCalibration: attempting to invert non-invertable transform");
        NSLog(@"M11: %f, M22 %f, M12: %f, M21: %f", cal.calibration.m11, cal.calibration.m22,
              cal.calibration.m12, cal.calibration.m21);
        cal.calibration.m12 += 0.000001;
    }
    
	[unitsToDeg setTransformStruct:cal.calibration];
	[degToUnits setTransformStruct:cal.calibration];
	[degToUnits invert];
	calBezierPath = [NSBezierPath bezierPath];
	
// Mark the offsets that are being used for calibration with circles

	c = cal.currentOffsetDeg;
	[calBezierPath setLineWidth:kLineWidthDeg];							// line width in degrees
	for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
		[calBezierPath moveToPoint:NSMakePoint(cal.targetDeg[index].x - c.x + kCircleRadiusDeg, cal.targetDeg[index].y - c.y)];	
		[calBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(cal.targetDeg[index].x - c.x, cal.targetDeg[index].y - c.y)
												  radius:kCircleRadiusDeg startAngle:0.0 endAngle:360.0];
	}

// Mark the sites that the eye actually hits with small crosses

	for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
		actualDeg = [unitsToDeg transformPoint:cal.actualUnits[index]];
		[calBezierPath moveToPoint:NSMakePoint(actualDeg.x - kCrossArmDeg, actualDeg.y)];	
		[calBezierPath lineToPoint:NSMakePoint(actualDeg.x + kCrossArmDeg, actualDeg.y)];	
		[calBezierPath moveToPoint:NSMakePoint(actualDeg.x, actualDeg.y - kCrossArmDeg)];	
		[calBezierPath lineToPoint:NSMakePoint(actualDeg.x, actualDeg.y + kCrossArmDeg)];
	}

// Make a parallogram to show the distortion in the affine transform.  We make the area equal
// to the area bounded by the offset target locations.

// Note, this is currently a rough approximation.  The correct parallelogram area is bh,
// where b is the base and h is the height normal to the base

	xVectorSize = [degToUnits transformSize:NSMakeSize(1.0, 0.0)];
	yVectorSize = [degToUnits transformSize:NSMakeSize(0.0, 1.0)];
	xVector.x = xVectorSize.width;
	xVector.y = xVectorSize.height;
	yVector.x = yVectorSize.width;
	yVector.y = yVectorSize.height;

	factor = (cal.offsetSizeDeg * cal.offsetSizeDeg) / 
				(sqrt(xVector.x * xVector.x + xVector.y * xVector.y) *
				sqrt(yVector.x * yVector.x + yVector.y * yVector.y));
	factor = sqrt(factor) / 2;					// convert areal to linear and get half side
	xVector.x *= factor;
	xVector.y *= factor;
	yVector.x *= factor;
	yVector.y *= factor;
	
	for (index = xSum = ySum = 0; index < kLLEyeCalibratorOffsets; index++) {
		xSum += cal.actualUnits[index].x;
		ySum += cal.actualUnits[index].y;
	}
	a = [unitsToDeg transformPoint:NSMakePoint(xSum / kLLEyeCalibratorOffsets, ySum / kLLEyeCalibratorOffsets)];
	[calBezierPath moveToPoint:
				NSMakePoint(a.x - xVector.x - yVector.x, a.y - xVector.y - yVector.y)];
	[calBezierPath lineToPoint:
				NSMakePoint(a.x - xVector.x + yVector.x, a.y - xVector.y + yVector.y)];
	[calBezierPath lineToPoint:
				NSMakePoint(a.x + xVector.x + yVector.x, a.y + xVector.y + yVector.y)];
	[calBezierPath lineToPoint:
				NSMakePoint(a.x + xVector.x - yVector.x, a.y + xVector.y - yVector.y)];
	[calBezierPath lineToPoint:
				NSMakePoint(a.x - xVector.x - yVector.x, a.y - xVector.y - yVector.y)];

	[unitsToDeg release];
	[degToUnits release];
	return calBezierPath;
}

- (NSAffineTransformStruct)calibration {

	return currentCalibration;
}

- (LLEyeCalibrationData *)calibrationData;
{	
	long index;
	
	data.offsetSizeDeg = [taskDefaults floatForKey:LLFixCalOffsetDegKey];
	data.currentOffsetDeg = [self calibrationOffsetPointDeg];
	for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
		data.actualUnits[index] = offsetUnits[index];
		data.targetDeg[index] = offsetDeg[index];
	}
	data.calibration = currentCalibration;
	return &data;
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

- (IBAction)changeToDefaults:(id)sender;
{
	[taskDefaults setFloat:kDefaultM11 forKey:[self keyFor:@"M11"]];
	[taskDefaults setFloat:kDefaultM12 forKey:[self keyFor:@"M12"]];
	[taskDefaults setFloat:kDefaultM21 forKey:[self keyFor:@"M21"]];
	[taskDefaults setFloat:kDefaultM22 forKey:[self keyFor:@"M22"]];
	[taskDefaults setFloat:kDefaultTX forKey:[self keyFor:@"TX"]];
	[taskDefaults setFloat:kDefaultTY forKey:[self keyFor:@"TY"]];
	[self readDefaults];							// Load transforms and compute parameters 
}

/*
Find the best fitting affine transform.  
Calibration is done by offseting the fixation point to the corners of square on different trials.  These corners 
(in units of degrees of azimuth and elevation) define a 2x4 matrix of values (4 pairs of x,y), Y.  The running average 
of eye positions values (in A/D units) associated with each of these offsets defines another 2x4 matrix, X. We want an 
affine transform, A, (2x2 matrix (without translation)) that minimizes the squared error between transformed X and Y (Y = AX).  
The transform that minimizes this error is given by A = YX+ where X+ is the pseudoinverse of X, 
A = YX+= Y Xt (X Xt)^-1, where Xt is X transposed. 
*/

- (void)computeTransformFromOffsets;
{
	NSAffineTransformStruct calibration;
//	NSAffineTransform *trans;

	calibration = [SVDSolver solveCalibration:kLLEyeCalibratorOffsets degPoints:offsetDeg unitPoints:offsetUnits];

// Save the new calibration

	[taskDefaults setFloat:calibration.m11 forKey:[self keyFor:@"M11"]];
	[taskDefaults setFloat:calibration.m12 forKey:[self keyFor:@"M12"]];
	[taskDefaults setFloat:calibration.m21 forKey:[self keyFor:@"M21"]];
	[taskDefaults setFloat:calibration.m22 forKey:[self keyFor:@"M22"]];
	[taskDefaults setFloat:calibration.tX forKey:[self keyFor:@"TX"]];
	[taskDefaults setFloat:calibration.tY forKey:[self keyFor:@"TY"]];
	
	currentCalibration = calibration;
	[self loadTransforms];
}

- (void)dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[degToUnits release];
	[unitsToDeg release];
	[taskDefaults release];
	[SVDSolver release];
    [keyPrefix release];
	[super dealloc];
}

- (NSPoint)degPointFromUnitPoint:(NSPoint)unitPoint {
   
   return [unitsToDeg transformPoint:unitPoint];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"%@: m11 %.6f  m12 %.6f  %m21 %.6f  %m22 %.6f  tX %.2f  tY %.2f", [self class],
		currentCalibration.m11, currentCalibration.m12, currentCalibration.m21, currentCalibration.m22,
		currentCalibration.tX, currentCalibration.tY];
}

- (id)init;
{
    if ((self = [super initWithWindowNibName:@"LLEyeCalibrator"]) != nil) {
        keyPrefix = [@"LLFixCal" retain];
        [self initFinish];
    }
    return self;
}

- (void)initFinish;
{        
	NSString *defaultsPath;
	NSDictionary *defaultsDict;

    [self setWindowFrameAutosaveName:@"LLEyeCalibrator"];
    unitsToDeg = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
    degToUnits = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
    SVDSolver = [[LLSVDSolver alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:)
                                                 name:LLSettingsChanged object:nil];
    
    // Set default calibration values, then try to read stored values
    
    defaultsPath = [[NSBundle bundleForClass:[LLEyeCalibrator class]] pathForResource:@"LLEyeCalibrator" ofType:@"plist"];
    defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
    taskDefaults = [[NSUserDefaults standardUserDefaults] retain];
    [taskDefaults registerDefaults:defaultsDict];
    [self readDefaults];
}

- (id)initWithKeyPrefix:(NSString *)theKey;
{
    if ((self = [super initWithWindowNibName:@"LLEyeCalibrator"]) != nil) {
        keyPrefix = theKey;
        [keyPrefix retain];
        [self initFinish];
    }
    return self;
}

- (NSString *)keyFor:(NSString *)keyType;
{
    return [NSString stringWithFormat:@"%@%@", keyPrefix, keyType];
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

	for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
		offsetDeg[index].x = ((index % 2) ? azimuthDeg + halfCalOffsetDeg : azimuthDeg - halfCalOffsetDeg);
		offsetDeg[index].y = ((index / 2) ? elevationDeg - halfCalOffsetDeg : elevationDeg + halfCalOffsetDeg);
		offsetUnits[index] = [self unitPointFromDegPoint:offsetDeg[index]];
	}	
}

// Load the tranforms with the currentCalibration values

- (void)loadTransforms;
{
    
    if (currentCalibration.m11 * currentCalibration.m22 - currentCalibration.m12 * currentCalibration.m21 == 0) {
        NSLog(@"LLEyeCalibrator +bezierPathForCalibration: attempting to invert non-invertable transform");
        NSLog(@"M11: %f, M22 %f, M12: %f, M21: %f", currentCalibration.m11, currentCalibration.m22,
              currentCalibration.m12, currentCalibration.m21);
        currentCalibration.m12 += 0.000001;
    }
    
	[unitsToDeg setTransformStruct:currentCalibration];
	[degToUnits setTransformStruct:currentCalibration];
	[degToUnits invert];
}

- (long)nextCalibrationPosition;
{
	double halfOffsetDeg;
	long index;
	
// If we have completed a block of positions, we need to update the calibration before moving on

	if (positionsDone >= kLLEyeCalibratorOffsets) {
		halfOffsetDeg = [taskDefaults floatForKey:LLFixCalOffsetDegKey] / 2.0;
		if (halfOffsetDeg > 0) {								// avoid degenerate case
			[self computeTransformFromOffsets];
		}
		for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
			positionDone[index] = NO;
		}
		positionsDone = 0;
	}

// Choose a new offset to test
		
	offsetIndex = (rand() % kLLEyeCalibratorOffsets);
	while (positionDone[offsetIndex]) {
		offsetIndex = (offsetIndex + 1) % kLLEyeCalibratorOffsets;
	}
	currentCalibration = [self readCalibration];
	currentCalibration.tX -= offsetDeg[offsetIndex].x;
	currentCalibration.tY -= offsetDeg[offsetIndex].y;
	[self loadTransforms];
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
	
	currentCalibration = [self readCalibration];
	[self loadTransforms];
	for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
		positionDone[index] = NO;
	}
	positionsDone = 0;

// Load the offset values.  The fixation azimuth and elevation offsets are added in here 

	[self loadOffsets];
}

- (NSAffineTransformStruct)readCalibration;
{
	NSAffineTransformStruct calibration;
	
	calibration.m11 = [taskDefaults floatForKey:[self keyFor:@"M11"]];
	calibration.m12 = [taskDefaults floatForKey:[self keyFor:@"M12"]];
	calibration.m21 = [taskDefaults floatForKey:[self keyFor:@"M21"]];
	calibration.m22 = [taskDefaults floatForKey:[self keyFor:@"M22"]];
	calibration.tX = [taskDefaults floatForKey:[self keyFor:@"TX"]];
	calibration.tY = [taskDefaults floatForKey:[self keyFor:@"TY"]];
	return calibration;
}

- (void)readDefaults;
{
	offsetIndex = -1;
	currentCalibration = [self readCalibration];
	if (currentCalibration.m11 == 0) {
		currentCalibration.m11 = kDefaultScaleFactor;
	}
	if (currentCalibration.m22 == 0) {
		currentCalibration.m22 = kDefaultScaleFactor;
	}
	[self loadTransforms];

// Set the calibration structure for the transforms.  We have to first set it
// without the fixation window offset, so that we can use it to compute the
// fixation window offset.  Once the offset is calculated, we load the 
// full transform.

	[self loadOffsets];
}

// set the size of the offset step that will be used for calibration
 
- (void)setCalibrationOffsetDeg:(float)newOffset;
{
	[taskDefaults setFloat:newOffset forKey:LLFixCalOffsetDegKey];
	[self parametersChanged:self];
}

// When we use two calibrators, only one of them will select the next offset to use (via nextCalibrationPosition).
// The second calibrator is kept in synch by passing the newly selected offset to it using this function.

- (void)setCalibrationPosition:(long)newOffsetIndex;
{
    long index;
	double halfOffsetDeg;
	
// If we have completed a block of positions, we need to update the calibration before moving on
    
	if (positionsDone >= kLLEyeCalibratorOffsets) {
		halfOffsetDeg = [taskDefaults floatForKey:LLFixCalOffsetDegKey] / 2.0;
		if (halfOffsetDeg > 0) {								// avoid degenerate case
			[self computeTransformFromOffsets];
		}
		for (index = 0; index < kLLEyeCalibratorOffsets; index++) {
			positionDone[index] = NO;
		}
		positionsDone = 0;
	}
    offsetIndex = newOffsetIndex;
	currentCalibration = [self readCalibration];
	currentCalibration.tX -= offsetDeg[offsetIndex].x;
	currentCalibration.tY -= offsetDeg[offsetIndex].y;
	[self loadTransforms];
}

- (void)setDefaults:(NSUserDefaults *)newDefaults;
{
	[taskDefaults release];
	taskDefaults = newDefaults;
	[taskDefaults retain];
}

- (void)setFixAzimuthDeg:(float)newAzimuthDeg elevationDeg:(float)newElevationDeg;
{
	[taskDefaults setFloat:newAzimuthDeg forKey:LLFixCalAzimuthDegKey];
	[taskDefaults setFloat:newElevationDeg forKey:LLFixCalElevationDegKey];
	[self parametersChanged:self];
}

- (void)setKeyPrefix:(NSString *)newKey;
{
    [keyPrefix autorelease];
    keyPrefix = newKey;
    [keyPrefix retain];
    [self readDefaults];
}

// This function gets called at initialization and when the settings folder is changed.
// Neither of these should happen when the task is running.

- (void)settingsChanged:(NSNotification *)notification {

	[self readDefaults];
}

- (NSPoint)unitPointFromDegPoint:(NSPoint)degPoint {

	return [degToUnits transformPoint:degPoint];
}

- (NSRect)unitRectFromDegRect:(NSRect)degRect;
{
	NSRect unitRect;

	unitRect.origin = [degToUnits transformPoint:degRect.origin];
	unitRect.size = [degToUnits transformSize:degRect.size];
	if (unitRect.size.width < 0) {
		unitRect.size.width = -unitRect.size.width;
		unitRect.origin.x -= unitRect.size.width;
	}
	if (unitRect.size.height < 0) {
		unitRect.size.height = -unitRect.size.height;
		unitRect.origin.y -= unitRect.size.height;
	}
	return unitRect;
}

- (NSRect)unitRectFromEyeWindow:(LLEyeWindow *)eyeWindow;
{
	NSRect unitRect, degRect;

	degRect = [eyeWindow rectDeg];
	unitRect.origin = [degToUnits transformPoint:degRect.origin];
	unitRect.size = [degToUnits transformSize:degRect.size];
//	unitRect.size.width = fabsf(unitRect.size.width);
//	unitRect.size.height = fabsf(unitRect.size.height);
	if (unitRect.size.width < 0) {
		unitRect.size.width = -unitRect.size.width;
		unitRect.origin.x -= unitRect.size.width;
	}
	if (unitRect.size.height < 0) {
		unitRect.size.height = -unitRect.size.height;
		unitRect.origin.y -= unitRect.size.height;
	}	
	return unitRect;
}

- (NSSize)unitSizeFromDegSize:(NSSize)sizeDeg;
{
	NSSize unitSize = [degToUnits transformSize:sizeDeg];
	
	unitSize.width = fabs(unitSize.width);
	unitSize.height = fabs(unitSize.height);
	return unitSize;
}

- (void)updateCalibration:(NSPoint)pointDeg;
{
	NSPoint unitPoint;
	
	unitPoint = [degToUnits transformPoint:pointDeg];
	offsetUnits[offsetIndex].x = offsetUnits[offsetIndex].x + (unitPoint.x - offsetUnits[offsetIndex].x) *
				[taskDefaults floatForKey:LLFixCorrectFactorKey];
	offsetUnits[offsetIndex].y = offsetUnits[offsetIndex].y + (unitPoint.y - offsetUnits[offsetIndex].y) *
				[taskDefaults floatForKey:LLFixCorrectFactorKey];
	positionDone[offsetIndex] = YES;
	positionsDone++;
}

@end
