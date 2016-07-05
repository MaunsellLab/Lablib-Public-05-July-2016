//
//  TUNEyeXYController.m
//  Experiment
//
//  XY Display of eye position.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "TUNEyeXYController.h"

#define kCircleRadiusDeg	0.15
#define kCrossArmDeg		0.25
#define kLineWidthDeg		0.02

NSString *TUNEyeXYDoGridKey = @"TUNEyeXYDoGrid";
NSString *TUNEyeXYDoTicksKey = @"TUNEyeXYDoTicks";
NSString *TUNEyeXYSamplesSavedKey = @"TUNEyeXYSamplesSaved";
NSString *TUNEyeXYDotSizeDegKey = @"TUNEyeXYDotSizeDeg";
NSString *TUNEyeXYDrawCalKey = @"TUNEyeXYDrawCal";
NSString *TUNEyeXYEyeColorKey = @"TUNEyeXYEyeColor";
NSString *TUNEyeXYFadeDotsKey = @"TUNEyeXYFadeDots";
NSString *TUNEyeXYGridDegKey = @"TUNEyeXYGridDeg";
NSString *TUNEyeXYHScrollKey = @"TUNEyeXYHScroll";
NSString *TUNEyeXYMagKey = @"TUNEyeXYMag";
NSString *TUNEyeXYOneInNKey = @"TUNEyeXYOneInN";
NSString *TUNEyeXYVScrollKey = @"TUNEyeXYVScroll";
NSString *TUNEyeXYTickDegKey = @"TUNEyeXYTickDeg";
NSString *TUNEyeXYWindowVisibleKey = @"TUNEyeXYWindowVisible";

NSString *TUNXYAutosaveKey = @"TUNXYAutosave";

@implementation TUNEyeXYController

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
	[[task defaults] setFloat:r.origin.x forKey:TUNEyeXYHScrollKey];
	[[task defaults] setFloat:r.origin.y forKey:TUNEyeXYVScrollKey];
	[fixWindowColor release];
	[respWindowColor release];
	[calColor release];
	[unitsToDeg release];
	[degToUnits release];
	[calBezierPath release];
	[eyeXSamples release];
	[eyeYSamples release];
	[sampleLock release];
    [super dealloc];
}

- (IBAction) doOptions:(id)sender {

    [NSApp beginSheet:optionsSheet modalForWindow:[self window] modalDelegate:self
        didEndSelector:nil contextInfo:nil];
}

// Because we have added ourself as an LLDrawable to the eyePlot, this draw method
// will be called every time eyePlot redraws.  This allows us to put in any specific
// windows, etc that we want to display.

- (void)draw;
{
	float defaultLineWidth = [NSBezierPath defaultLineWidth];

// Draw the fixation window

	if (inWindow) {
		[[fixWindowColor highlightWithLevel:0.90] set];
		[NSBezierPath fillRect:eyeWindowRectDeg];
	}
	[fixWindowColor set];
	[NSBezierPath setDefaultLineWidth:defaultLineWidth * 4.0]; 
	[NSBezierPath strokeRect:eyeWindowRectDeg];

// Draw the calibration for the fixation window
	
	if ([[task defaults] integerForKey:TUNEyeXYDrawCalKey]) {
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

    if ((self = [super initWithWindowNibName:@"TUNEyeXYController"]) != nil) {
		[[task defaults] registerDefaults:
					[NSDictionary dictionaryWithObject:
					[NSArchiver archivedDataWithRootObject:[NSColor blueColor]] 
					forKey:TUNEyeXYEyeColorKey]];
		eyeXSamples = [[NSMutableData alloc] init];
		eyeYSamples = [[NSMutableData alloc] init];
		sampleLock = [[NSLock alloc] init];
 		[self setShouldCascadeWindows:NO];
        [self setWindowFrameAutosaveName:TUNXYAutosaveKey];
        [self window];							// Force the window to load now
    }
    return self;
}

- (void)processEyeSamplePairs;
{
	long index;
	NSEnumerator *enumerator;
	NSArray *pairs;
	NSValue *value;
	
	[sampleLock lock];
	pairs = [LLDataUtil pairXSamples:eyeXSamples withYSamples:eyeYSamples];
	[sampleLock unlock];
	if (pairs != nil) {
		enumerator = [pairs objectEnumerator];
		while (value = [enumerator nextObject]) {
			currentEyeDeg = [unitsToDeg transformPoint:[value pointValue]];
			[eyePlot addSample:currentEyeDeg];
		}
	}
	if (!inWindow && NSPointInRect(currentEyeDeg, eyeWindowRectDeg) ||
				(inWindow && !NSPointInRect(currentEyeDeg, eyeWindowRectDeg))) {
		[eyePlot setNeedsDisplayInRect:[eyePlot pixRectFromDegRect:eyeWindowRectDeg]];
		inWindow = !inWindow;
	}
	for (index = 0; index < 2; index++) {
		if (!inRespWindow[index] && NSPointInRect(currentEyeDeg, respWindowRectDeg[index]) ||
				(inRespWindow[index] && !NSPointInRect(currentEyeDeg, respWindowRectDeg[index]))) {
			[eyePlot setNeedsDisplayInRect:
							[eyePlot pixRectFromDegRect:respWindowRectDeg[index]]];
			inRespWindow[index] = !inRespWindow[index];
		}
	}
}

- (void)setEyePlotValues {

	[eyePlot setDotSizeDeg:[[task defaults] floatForKey:TUNEyeXYDotSizeDegKey]];
	[eyePlot setDotFade:[[task defaults] boolForKey:TUNEyeXYFadeDotsKey]];
    [eyePlot setEyeColor:[NSUnarchiver 
                unarchiveObjectWithData:[[task defaults] 
                objectForKey:TUNEyeXYEyeColorKey]]];
	[eyePlot setGrid:[[task defaults] boolForKey:TUNEyeXYDoGridKey]];
	[eyePlot setGridDeg:[[task defaults] floatForKey:TUNEyeXYGridDegKey]];
	[eyePlot setOneInN:[[task defaults] integerForKey:TUNEyeXYOneInNKey]];
	[eyePlot setTicks:[[task defaults] boolForKey:TUNEyeXYDoTicksKey]];
	[eyePlot setTickDeg:[[task defaults] floatForKey:TUNEyeXYTickDegKey]];
	[eyePlot setSamplesToSave:[[task defaults] integerForKey:TUNEyeXYSamplesSavedKey]];
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

- (void)windowDidBecomeKey:(NSNotification *)aNotification;
{
	[[task defaults] setObject:[NSNumber numberWithBool:YES] forKey:TUNEyeXYWindowVisibleKey];
}

// Initialization is handled through the following delegate method for our window 

- (void) windowDidLoad;
{
    calColor = [[NSColor colorWithDeviceRed:0.60 green:0.45 blue:0.15 alpha:1.0] retain];
    fixWindowColor = [[NSColor colorWithDeviceRed:0.00 green:0.00 blue:1.00 alpha:1.0] retain];
    respWindowColor = [[NSColor colorWithDeviceRed:0.95 green:0.55 blue:0.50 alpha:1.0] retain];
	unitsToDeg = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
	degToUnits = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
    [self setScaleFactor:[[task defaults] floatForKey:TUNEyeXYMagKey]];
	[self setEyePlotValues];
	
	
	
	[eyePlot setDrawOnlyDirtyRect:NO];
    
	
	
	[eyePlot addDrawable:self];
	[self changeZoom:slider];
	[eyePlot scrollPoint:NSMakePoint(
            [[task defaults] floatForKey:TUNEyeXYHScrollKey], 
            [[task defaults] floatForKey:TUNEyeXYVScrollKey])];
	
	[[self window] setFrameUsingName:TUNXYAutosaveKey];			// Needed when opened a second time
    if ([[task defaults] boolForKey:TUNEyeXYWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }

    [scrollView setPostsBoundsChangedNotifications:YES];
    [super windowDidLoad];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification;
{
    [[self window] orderOut:self];
    [[task defaults] setObject:[NSNumber numberWithBool:NO] forKey:TUNEyeXYWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

// Methods related to data events follow:

// Update the display of the calibration in the xy window.  We get the calibration structure
// and use it to construct crossing lines that mark the current calibration.

- (void)eyeCalibration:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	LLEyeCalibrationData cal;

	[eventData getBytes:&cal];
	[unitsToDeg setTransformStruct:cal.calibration];
	[degToUnits setTransformStruct:cal.calibration];
	[degToUnits invert];

	[calBezierPath release];
	calBezierPath = [LLEyeCalibrator bezierPathForCalibration:cal];
	[calBezierPath retain];
}

- (void)eyeWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	FixWindowData fixWindowData;
    
	[eventData getBytes:&fixWindowData];
	eyeWindowRectDeg = fixWindowData.windowDeg;
	[eyePlot setNeedsDisplayInRect:NSInsetRect(
		[eyePlot pixRectFromDegRect:eyeWindowRectDeg],
		-2.5, -2.5)];
}

// Just save the x eye data until we get the corresponding y eye data

- (void)eyeXData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[sampleLock lock];
	[eyeXSamples appendData:eventData];
	[sampleLock unlock];
	[self processEyeSamplePairs];
}

- (void)eyeYData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[sampleLock lock];
	[eyeYSamples appendData:eventData];
	[sampleLock unlock];
	[self processEyeSamplePairs];
}

- (void)responseWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	FixWindowData respWindowData;
    
	[eventData getBytes:&respWindowData];
	respWindowRectDeg[respWindowData.index] = respWindowData.windowDeg;
	[eyePlot setNeedsDisplayInRect:NSInsetRect(
			[eyePlot pixRectFromDegRect:respWindowRectDeg[respWindowData.index]], 
			-2.5, -2.5)];
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
//	long index;
	
	[eventData getBytes:&trial];
    inTrial = YES;
    [eyePlot setNeedsDisplay:YES];
//	for (index = 0; index < 2; index++) {
//		[eyePlot setNeedsDisplayInRect:NSInsetRect(
//			[eyePlot pixRectFromDegRect:respWindowRectDeg[index]], 
//			-2.5, -2.5)];
//	}
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long index;
	
	inTrial = NO;
	for (index = 0; index < 2; index++) {
		[eyePlot setNeedsDisplayInRect:NSInsetRect(
			[eyePlot pixRectFromDegRect:respWindowRectDeg[index]], 
			-2.5, -2.5)];
	}
}

@end
