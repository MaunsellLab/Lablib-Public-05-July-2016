//
//  VTEyeXYController.m
//  Experiment
//
//  XY Display of eye position.
//
//  Created by John Maunsell on Fri Apr 11 2003.
//  Copyright (c) 2003. All rights reserved.
//

#define NoGlobals

#import "VTEyeXYController.h"

#define kCircleRadiusDeg	0.15
#define kCrossArmDeg		0.25
#define kLineWidthDeg		0.02

NSString *VTEyeXYDoGridKey = @"VTEyeXYDoGrid";
NSString *VTEyeXYDoTicksKey = @"VTEyeXYDoTicks";
NSString *VTEyeXYSamplesSavedKey = @"VTEyeXYSamplesSaved";
NSString *VTEyeXYDotSizeDegKey = @"VTEyeXYDotSizeDeg";
NSString *VTEyeXYDrawCalKey = @"VTEyeXYDrawCal";
NSString *VTEyeXYEyeColorKey = @"VTEyeXYEyeColor";
NSString *VTEyeXYFadeDotsKey = @"VTEyeXYFadeDots";
NSString *VTEyeXYGridDegKey = @"VTEyeXYGridDeg";
NSString *VTEyeXYHScrollKey = @"VTEyeXYHScroll";
NSString *VTEyeXYMagKey = @"VTEyeXYMag";
NSString *VTEyeXYOneInNKey = @"VTEyeXYOneInN";
NSString *VTEyeXYVScrollKey = @"VTEyeXYVScroll";
NSString *VTEyeXYTickDegKey = @"VTEyeXYTickDeg";
NSString *VTEyeXYWindowVisibleKey = @"VTEyeXYWindowVisible";

NSString *VTXYAutosaveKey = @"VTXYAutosave";

@implementation VTEyeXYController

- (IBAction)centerDisplay:(id)sender {

    [eyePlot centerDisplay];
}

- (IBAction)changeZoom:(id)sender {

    [self setScaleFactor:[sender floatValue]];
}

// Prepare to be destroyed.  This odd method is needed because we increased our retainCount when we added
// ourselves to eyePlot (in windowDidLoad).  Owing to that increment, the object that created us will never
// get us to a retainCount of zero when it releases us.  For that reason, we need this method as a route
// for our creating object to get us to get us released from eyePlot and prepared to be fully released.

- (void)deactivate;
{
	[eyePlot removeDrawable:self];			// Remove ourselves, lowering our retainCount;
	[self close];							// clean up
}

- (void) dealloc;
{
	NSRect r;

	r = [eyePlot visibleRect];
	[[task defaults] setFloat:r.origin.x forKey:VTEyeXYHScrollKey];
	[[task defaults] setFloat:r.origin.y forKey:VTEyeXYVScrollKey];
	[fixWindowColor release];
	[respWindowColor release];
	[calColor release];
	[unitsToDeg release];
	[degToUnits release];
	[calBezierPath release];
    [super dealloc];
}

- (IBAction) doOptions:(id)sender {

    [NSApp beginSheet:optionsSheet modalForWindow:[self window] modalDelegate:self
        didEndSelector:nil contextInfo:nil];
}

// Because we have added ourself as an LLDrawable to the eyePlot, this draw method
// will be called every time eyePlot redraws.  This allows us to put in any specific
// windows, etc that we want to display.

- (void)draw {

	long interval;
	float defaultLineWidth = [NSBezierPath defaultLineWidth];

// Draw the fixation window

	if (NSPointInRect(currentEyeDeg, eyeWindowRectDeg)) {
		[[fixWindowColor highlightWithLevel:0.90] set];
		[NSBezierPath fillRect:eyeWindowRectDeg];
	}
	[fixWindowColor set];
	[NSBezierPath setDefaultLineWidth:defaultLineWidth * 4.0]; 
	[NSBezierPath strokeRect:eyeWindowRectDeg];

// Draw the response windows
	
	for (interval = 0; interval < 2; interval++) {
		if (NSPointInRect(currentEyeDeg, respWindowRectDeg[interval])) {
			[[respWindowColor highlightWithLevel:0.80] set];
			[NSBezierPath fillRect:respWindowRectDeg[interval]];
		}
		[respWindowColor set];
		if (inTrial && (interval == trial.stimulusInterval)) {
			[NSBezierPath setDefaultLineWidth:defaultLineWidth * 4.0]; 
		}
		else {
			[NSBezierPath setDefaultLineWidth:defaultLineWidth];
		}
		[NSBezierPath strokeRect:respWindowRectDeg[interval]];
	}
	[NSBezierPath setDefaultLineWidth:defaultLineWidth];

// Draw the calibration for the fixation window
	
	if ([[task defaults] integerForKey:VTEyeXYDrawCalKey]) {
		[calColor set];
		[calBezierPath stroke];
	}
}

- (IBAction) endOptionSheet:(id)sender {

	[self setEyePlotValues];
    [optionsSheet orderOut:sender];
    [NSApp endSheet:optionsSheet returnCode:1];
}

- (id)init {

    if ((self = [super initWithWindowNibName:@"VTEyeXYController"]) != nil) {
		[[task defaults] registerDefaults:
					[NSDictionary dictionaryWithObject:
					[NSArchiver archivedDataWithRootObject:[NSColor blueColor]] 
					forKey:VTEyeXYEyeColorKey]];
 		[self setShouldCascadeWindows:NO];
        [self setWindowFrameAutosaveName:VTXYAutosaveKey];
        [self window];							// Force the window to load now
    }
    return self;
}

- (void)setEyePlotValues {

	[eyePlot setDotSizeDeg:[[task defaults] floatForKey:VTEyeXYDotSizeDegKey]];
	[eyePlot setDotFade:[[task defaults] boolForKey:VTEyeXYFadeDotsKey]];
    [eyePlot setEyeColor:[NSUnarchiver 
                unarchiveObjectWithData:[[task defaults] 
                objectForKey:VTEyeXYEyeColorKey]]];
	[eyePlot setGrid:[[task defaults] boolForKey:VTEyeXYDoGridKey]];
	[eyePlot setGridDeg:[[task defaults] floatForKey:VTEyeXYGridDegKey]];
	[eyePlot setOneInN:[[task defaults] integerForKey:VTEyeXYOneInNKey]];
	[eyePlot setTicks:[[task defaults] boolForKey:VTEyeXYDoTicksKey]];
	[eyePlot setTickDeg:[[task defaults] floatForKey:VTEyeXYTickDegKey]];
	[eyePlot setSamplesToSave:[[task defaults] integerForKey:VTEyeXYSamplesSavedKey]];
}

// Change the scaling factor for the view
// Because scaleUnitSquareToSize acts on the current scaling, not the original scaling,
// we have to work out the current scaling using the relative scaling of the eyePlot and
// its superview

- (void) setScaleFactor:(double)factor;
{
	float currentFactor, applyFactor;
  
	currentFactor = [eyePlot bounds].size.width / [[eyePlot superview] bounds].size.width;
	applyFactor = factor / currentFactor;
	[[scrollView contentView] scaleUnitSquareToSize:NSMakeSize(applyFactor, applyFactor)];
	[self centerDisplay:self];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {

	[[task defaults] setObject:[NSNumber numberWithBool:YES] 
                forKey:VTEyeXYWindowVisibleKey];
}

// Initialization is handled through the following delegate method for our window 

- (void) windowDidLoad;
{
	[[self window] makeKeyAndOrderFront:self];
	calBezierPath = [[NSBezierPath alloc] init];
    calColor = [[NSColor colorWithDeviceRed:0.60 green:0.45 blue:0.15 alpha:1.0] retain];
    fixWindowColor = [[NSColor colorWithDeviceRed:0.00 green:0.00 blue:1.00 alpha:1.0] retain];
    respWindowColor = [[NSColor colorWithDeviceRed:0.95 green:0.55 blue:0.50 alpha:1.0] retain];
	unitsToDeg = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
	degToUnits = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
    [self setScaleFactor:[[task defaults] floatForKey:VTEyeXYMagKey]];
	[self setEyePlotValues];
    [eyePlot addDrawable:self];
	[self changeZoom:slider];
	[eyePlot scrollPoint:NSMakePoint(
            [[task defaults] floatForKey:VTEyeXYHScrollKey], 
            [[task defaults] floatForKey:VTEyeXYVScrollKey])];
	
	[[self window] setFrameUsingName:VTXYAutosaveKey];			// Needed when opened a second time
    if ([[task defaults] boolForKey:VTEyeXYWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }

    [scrollView setPostsBoundsChangedNotifications:YES];
    [super windowDidLoad];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification {

    [[self window] orderOut:self];
    [[task defaults] setObject:[NSNumber numberWithBool:NO] 
                forKey:VTEyeXYWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

// Methods related to data events follow:

// Update the display of the calibration in the xy window.  We get the calibration structure
// and use it to construct crossing lines that mark ±1 degree.

- (void)eyeCalibration:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long index;
	float factor, xSum, ySum;
	LLEyeCalibrationData cal;
	NSPoint xVector, yVector, actualDeg;
	NSSize xVectorSize, yVectorSize;
	NSPoint c, a;
	
	[eventData getBytes:&cal];
	[unitsToDeg setTransformStruct:cal.calibration];
	[degToUnits setTransformStruct:cal.calibration];
	[degToUnits invert];

// Draw bars to show the current calibration.  We construct a parallogram that reflect
// the X and Y scaling of where the actually fixation points are (when plotted in  
// isotropic degree space).
	

	[calBezierPath removeAllPoints];
	if (cal.offsetSizeDeg == 0) {
		return;
	}

// Make the offsets that are being used for calibration with circles

	[calBezierPath setLineWidth:kLineWidthDeg];							// line width in degrees
	c = cal.currentOffsetDeg;
	[calBezierPath moveToPoint:NSMakePoint(kCircleRadiusDeg, 0)];		// move so we don't draw a line
	[calBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(0, 0)
					radius:kCircleRadiusDeg startAngle:0.0 endAngle:360.0];
	[calBezierPath moveToPoint:NSMakePoint(-2 * c.x + kCircleRadiusDeg, 0)];
	[calBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(-2 * c.x, 0)
					radius:kCircleRadiusDeg startAngle:0.0 endAngle:360.0];
	[calBezierPath moveToPoint:NSMakePoint(-2 * c.x + kCircleRadiusDeg, -2 * c.y)];
	[calBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(-2 * c.x, -2 * c.y)
					radius:kCircleRadiusDeg startAngle:0.0 endAngle:360.0];
	[calBezierPath moveToPoint:NSMakePoint(kCircleRadiusDeg, -2 * c.y)];
	[calBezierPath appendBezierPathWithArcWithCenter:NSMakePoint(0, -2 * c.y)
					radius:kCircleRadiusDeg startAngle:0.0 endAngle:360.0];
	
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
}

- (void)eyeData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	short *pSamples;
	long samplePair, samplePairs, x, y;
	
	samplePairs = [eventData length] / (2 * sizeof(short));
	pSamples = (short *)[eventData bytes];
	for (samplePair = 0; samplePair < samplePairs; samplePair++) {
		x = *pSamples++;
		y = *pSamples++;
		currentEyeDeg = [unitsToDeg transformPoint:NSMakePoint(x, y)];
		[eyePlot addSample:currentEyeDeg];
	}
}

- (void)eyeWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	FixWindowData fixWindowData;
    
	[eventData getBytes:&fixWindowData];
	eyeWindowRectDeg = fixWindowData.windowDeg;
    [eyePlot setNeedsDisplay:YES];
}

- (void)responseWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	FixWindowData respWindowData;
    
	[eventData getBytes:&respWindowData];
	respWindowRectDeg[respWindowData.index] = respWindowData.windowDeg;
    [eyePlot setNeedsDisplay:YES];
}

- (void) trial:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&trial];
    inTrial = YES;
}

- (void) trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	inTrial = NO;
}

@end
