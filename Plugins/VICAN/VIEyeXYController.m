//
//  VIEyeXYController.m
//  Experiment
//
//  XY Display of eye position.
//
//  Copyright (c) 2012. All rights reserved.
//

#define NoGlobals

#import "VIEyeXYController.h"

#define kCircleRadiusDeg	0.15
#define kCrossArmDeg		0.25
#define kLineWidthDeg		0.02

NSString *VIEyeXYDoGridKey = @"VIEyeXYDoGrid";
NSString *VIEyeXYDoTicksKey = @"VIEyeXYDoTicks";
NSString *VIEyeXYSamplesSavedKey = @"VIEyeXYSamplesSaved";
NSString *VIEyeXYDotSizeDegKey = @"VIEyeXYDotSizeDeg";
NSString *VIEyeXYDrawCalKey = @"VIEyeXYDrawCal";
NSString *VIEyeXYLEyeColorKey = @"VIEyeXYLEyeColor";
NSString *VIEyeXYREyeColorKey = @"VIEyeXYREyeColor";
NSString *VIEyeXYFadeDotsKey = @"VIEyeXYFadeDots";
NSString *VIEyeXYGridDegKey = @"VIEyeXYGridDeg";
NSString *VIEyeXYHScrollKey = @"VIEyeXYHScroll";
NSString *VIEyeXYMagKey = @"VIEyeXYMag";
NSString *VIEyeXYOneInNKey = @"VIEyeXYOneInN";
NSString *VIEyeXYVScrollKey = @"VIEyeXYVScroll";
NSString *VIEyeXYTickDegKey = @"VIEyeXYTickDeg";
NSString *VIEyeXYWindowVisibleKey = @"VIEyeXYWindowVisible";

NSString *VIXYAutosaveKey = @"VIXYAutosave";


@implementation VIEyeXYController

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
    long eyeIndex;
	NSRect r;

	r = [eyePlot visibleRect];
	[[task defaults] setFloat:r.origin.x forKey:VIEyeXYHScrollKey];
	[[task defaults] setFloat:r.origin.y forKey:VIEyeXYVScrollKey];
	[fixWindowColor release];
	[respWindowColor release];
    for (eyeIndex = kLeftEye; eyeIndex < kEyes; eyeIndex++) {
        [unitsToDeg[eyeIndex] release];
        [degToUnits[eyeIndex] release];
        [calBezierPath[eyeIndex] release];
        [eyeXSamples[eyeIndex] release];
        [eyeYSamples[eyeIndex] release];
    }
	[sampleLock release];
    [super dealloc];
}

- (IBAction) doOptions:(id)sender;
{
    [NSApp beginSheet:optionsSheet modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

// Because we have added ourself as an LLDrawable to the eyePlot, this draw method will be called every time eyePlot 
// redraws.  This allows us to put in any specific windows, etc that we want to display.

- (void)draw;
{
	long index;
	float defaultLineWidth = [NSBezierPath defaultLineWidth];

// Draw the fixation window

	if (inWindow) {
		[[fixWindowColor highlightWithLevel:0.90] set];
		[NSBezierPath fillRect:eyeWindowRectDeg];
	}
	[fixWindowColor set];
	[NSBezierPath setDefaultLineWidth:defaultLineWidth * 4.0]; 
	[NSBezierPath strokeRect:eyeWindowRectDeg];

// Draw the response windows

	for (index = 0; index < kStimLocs; index++) {
		if (NSPointInRect(currentEyeDeg[kLeftEye], respWindowRectDeg[index]) ||
                            NSPointInRect(currentEyeDeg[kRightEye], respWindowRectDeg[index])) {
			[[respWindowColor highlightWithLevel:0.80] set];
			[NSBezierPath fillRect:respWindowRectDeg[index]];
		}
		[respWindowColor set];
        [NSBezierPath setDefaultLineWidth:defaultLineWidth];
		if (inTrial) {
            if (index == trial.targetPos) {
                [NSBezierPath setDefaultLineWidth:defaultLineWidth * 8.0];
            }
            else if (index == trial.attendLoc) {
                [NSBezierPath setDefaultLineWidth:defaultLineWidth * 4.0];
            }
        }
		[NSBezierPath strokeRect:respWindowRectDeg[index]];
	}
	[NSBezierPath setDefaultLineWidth:defaultLineWidth];

// Draw the calibration for the fixation window
	
	if ([[task defaults] integerForKey:VIEyeXYDrawCalKey]) {
        [[eyePlot eyeLColor] set];
		[calBezierPath[kLeftEye] stroke];
        [[eyePlot eyeRColor] set];
		[calBezierPath[kRightEye] stroke];
	}
}

- (IBAction) endOptionSheet:(id)sender;
{
	[self setEyePlotValues];
    [optionsSheet orderOut:sender];
    [NSApp endSheet:optionsSheet returnCode:1];
}

- (id)init;
{
    if ((self = [super initWithWindowNibName:@"VIEyeXYController"]) != nil) {
		[[task defaults] registerDefaults:[NSDictionary dictionaryWithObject:
                            [NSArchiver archivedDataWithRootObject:[NSColor blueColor]] forKey:VIEyeXYLEyeColorKey]];
		[[task defaults] registerDefaults:[NSDictionary dictionaryWithObject:
                            [NSArchiver archivedDataWithRootObject:[NSColor redColor]] forKey:VIEyeXYREyeColorKey]];
		eyeXSamples[kLeftEye] = [[NSMutableData alloc] init];
		eyeYSamples[kLeftEye] = [[NSMutableData alloc] init];
		eyeXSamples[kRightEye] = [[NSMutableData alloc] init];
		eyeYSamples[kRightEye] = [[NSMutableData alloc] init];
		sampleLock = [[NSLock alloc] init];
 		[self setShouldCascadeWindows:NO];
        [self setWindowFrameAutosaveName:VIXYAutosaveKey];
        [self window];							// Force the window to load now
    }
    return self;
}

- (void)processEyeSamplePairs:(long)eyeIndex;
{
	long index;
    NSPoint newEyeDeg;
    float eyeFilter = [[task defaults] floatForKey:@"VIEyeFilter"];

	NSEnumerator *enumerator;
	NSArray *pairs;
	NSValue *value;
	
    [sampleLock lock];
    pairs = [LLDataUtil pairXSamples:eyeXSamples[eyeIndex] withYSamples:eyeYSamples[eyeIndex]];
    [sampleLock unlock];
    if (pairs != nil) {
        enumerator = [pairs objectEnumerator];
        while (value = [enumerator nextObject]) {
            newEyeDeg = [unitsToDeg[eyeIndex] transformPoint:[value pointValue]];
            currentEyeDeg[eyeIndex].x = newEyeDeg.x * eyeFilter + currentEyeDeg[eyeIndex].x * (1 - eyeFilter);
            currentEyeDeg[eyeIndex].y = newEyeDeg.y * eyeFilter + currentEyeDeg[eyeIndex].y * (1 - eyeFilter);
            [eyePlot addSample:currentEyeDeg[eyeIndex] forEye:eyeIndex];
        }
    }
	if ((!inWindow &&
                (NSPointInRect(currentEyeDeg[kLeftEye], eyeWindowRectDeg) || 
                 NSPointInRect(currentEyeDeg[kRightEye], eyeWindowRectDeg))) ||
				(inWindow && (!NSPointInRect(currentEyeDeg[kLeftEye], eyeWindowRectDeg) &&
                              !NSPointInRect(currentEyeDeg[kRightEye], eyeWindowRectDeg)))) {
        [eyePlot setNeedsDisplayInRect:[eyePlot pixRectFromDegRect:eyeWindowRectDeg]];
		inWindow = !inWindow;
	}
    
	for (index = 0; index < kStimLocs; index++) {
		if ((!inRespWindow[index] && 
                            (NSPointInRect(currentEyeDeg[kLeftEye], respWindowRectDeg[index]) || 
                            NSPointInRect(currentEyeDeg[kRightEye], respWindowRectDeg[index]))) ||
                            (inRespWindow[index] && (!NSPointInRect(currentEyeDeg[kLeftEye], respWindowRectDeg[index]) &&
                            !NSPointInRect(currentEyeDeg[kRightEye], respWindowRectDeg[index])))) {
			[eyePlot setNeedsDisplayInRect:NSInsetRect([eyePlot pixRectFromDegRect:respWindowRectDeg[index]],
                                        -2.5, -2.5)];
			inRespWindow[index] = !inRespWindow[index];
		}
	}
}

- (void)setEyePlotValues;
{
	[eyePlot setDotSizeDeg:[[task defaults] floatForKey:VIEyeXYDotSizeDegKey]];
	[eyePlot setDotFade:[[task defaults] boolForKey:VIEyeXYFadeDotsKey]];
    [eyePlot setEyeColor:[NSUnarchiver unarchiveObjectWithData:[[task defaults] objectForKey:VIEyeXYLEyeColorKey]]
                forEye:kLeftEye];
    [eyePlot setEyeColor:[NSUnarchiver unarchiveObjectWithData:[[task defaults] objectForKey:VIEyeXYREyeColorKey]]
                forEye:kRightEye];
	[eyePlot setGrid:[[task defaults] boolForKey:VIEyeXYDoGridKey]];
	[eyePlot setGridDeg:[[task defaults] floatForKey:VIEyeXYGridDegKey]];
	[eyePlot setOneInN:[[task defaults] integerForKey:VIEyeXYOneInNKey]];
	[eyePlot setTicks:[[task defaults] boolForKey:VIEyeXYDoTicksKey]];
	[eyePlot setTickDeg:[[task defaults] floatForKey:VIEyeXYTickDegKey]];
	[eyePlot setSamplesToSave:[[task defaults] integerForKey:VIEyeXYSamplesSavedKey]];
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

- (void)updateEyeCalibration:(long)eyeIndex eventData:(NSData *)eventData;
{
	LLEyeCalibrationData cal;
    
	[eventData getBytes:&cal length:sizeof(LLEyeCalibrationData)];
    
	[unitsToDeg[eyeIndex] setTransformStruct:cal.calibration];
	[degToUnits[eyeIndex] setTransformStruct:cal.calibration];
	[degToUnits[eyeIndex] invert];
    
	[calBezierPath[eyeIndex] autorelease];
	calBezierPath[eyeIndex] = [LLEyeCalibrator bezierPathForCalibration:cal];
	[calBezierPath[eyeIndex] retain];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification;
{
	[[task defaults] setObject:[NSNumber numberWithBool:YES] forKey:VIEyeXYWindowVisibleKey];
}

// Initialization is handled through the following delegate method for our window 

- (void) windowDidLoad;
{
    fixWindowColor = [[NSColor colorWithDeviceRed:0.00 green:0.00 blue:1.00 alpha:1.0] retain];
    respWindowColor = [[NSColor colorWithDeviceRed:0.95 green:0.55 blue:0.50 alpha:1.0] retain];
	unitsToDeg[kLeftEye] = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
	unitsToDeg[kRightEye] = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
	degToUnits[kLeftEye] = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
	degToUnits[kRightEye] = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
    [self setScaleFactor:[[task defaults] floatForKey:VIEyeXYMagKey]];
	[self setEyePlotValues];
	[eyePlot setDrawOnlyDirtyRect:YES];
    [eyePlot addDrawable:self];
	[self changeZoom:slider];
	[eyePlot scrollPoint:NSMakePoint([[task defaults] floatForKey:VIEyeXYHScrollKey], 
            [[task defaults] floatForKey:VIEyeXYVScrollKey])];
	
	[[self window] setFrameUsingName:VIXYAutosaveKey];			// Needed when opened a second time
    if ([[task defaults] boolForKey:VIEyeXYWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }

    [scrollView setPostsBoundsChangedNotifications:YES];
    [filterFormatter setMinimum:[NSNumber numberWithFloat:0.01]];        // Shouldn't need to do this
    [super windowDidLoad];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification;
{
    [[self window] orderOut:self];
    [[task defaults] setObject:[NSNumber numberWithBool:NO] forKey:VIEyeXYWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

// Methods related to data events follow:

// Update the display of the calibration in the xy window.  We get the calibration structure
// and use it to construct crossing lines that mark the current calibration.

- (void)eyeLeftCalibration:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    [self updateEyeCalibration:kLeftEye eventData:eventData];
}

- (void)eyeRightCalibration:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    [self updateEyeCalibration:kRightEye eventData:eventData];
}

- (void)eyeWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	FixWindowData fixWindowData;
    
	[eventData getBytes:&fixWindowData length:sizeof(FixWindowData)];
	eyeWindowRectDeg = fixWindowData.windowDeg;
	[eyePlot setNeedsDisplayInRect:NSInsetRect([eyePlot pixRectFromDegRect:eyeWindowRectDeg], -2.5, -2.5)];
}

// Just save the x eye data until we get the corresponding y eye data

- (void)eyeLXData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[sampleLock lock];
	[eyeXSamples[kLeftEye] appendData:eventData];
	[sampleLock unlock];
    [self processEyeSamplePairs:kLeftEye];
}

- (void)eyeLYData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[sampleLock lock];
	[eyeYSamples[kLeftEye] appendData:eventData];
	[sampleLock unlock];
}

- (void)eyeRXData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[sampleLock lock];
	[eyeXSamples[kRightEye] appendData:eventData];
	[sampleLock unlock];
}

- (void)eyeRYData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[sampleLock lock];
	[eyeYSamples[kRightEye] appendData:eventData];
	[sampleLock unlock];
    [self processEyeSamplePairs:kRightEye];
}

- (void)responseWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	FixWindowData respWindowData;
    
	[eventData getBytes:&respWindowData length:sizeof(FixWindowData)];
	respWindowRectDeg[respWindowData.index] = respWindowData.windowDeg;
	[eyePlot setNeedsDisplayInRect:
                    NSInsetRect([eyePlot pixRectFromDegRect:respWindowRectDeg[respWindowData.index]], -2.5, -2.5)];
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long index;
	
	[eventData getBytes:&trial length:sizeof(TrialDesc)];
    inTrial = YES;
    [eyePlot setNeedsDisplay:YES];
	for (index = 0; index < kStimLocs; index++) {
		[eyePlot setNeedsDisplayInRect:NSInsetRect( [eyePlot pixRectFromDegRect:respWindowRectDeg[index]], -2.5, -2.5)];
	}
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long index;
	
	inTrial = NO;
	for (index = 0; index < 2; index++) {
		[eyePlot setNeedsDisplayInRect:NSInsetRect([eyePlot pixRectFromDegRect:respWindowRectDeg[index]],-2.5, -2.5)];
	}
}



@end
