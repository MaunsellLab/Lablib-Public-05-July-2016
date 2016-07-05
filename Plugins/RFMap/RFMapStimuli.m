/*
RFMapStimuli.m
Stimulus generation
December 26, 2004 John Maunsell
*/

#import "RFMapStimuli.h"
#import "RF.h"
#import <Carbon/Carbon.h>
#import <OpenGL/gl.h>

#define kAutoreleaseIntS	10
#define kMidGray				0.5
#define kGridGray				0.6
#define kRadiansPerDeg			(kPI / 180.0)

static NSString *RFMonitorIDString = @"RFMapStimulus";

@implementation RFMapStimuli

- (void)changeSize:(float)factor;
{
	switch (stimType) {
		case kBarStimulus:
			[bar setLengthDeg:([bar lengthDeg]  * factor)];
			break;
		case kGaborStimulus:
			[gabor setRadiusDeg:([gabor radiusDeg]  * factor)];
			[gabor setSigmaDeg:([gabor sigmaDeg]  * factor)];
			break;
		case kDotsStimulus:
			[dots setRadiusDeg:([dots radiusDeg]  * factor)];
			break;
		case kPlaidStimulus:
			[plaid setRadiusDeg:([plaid radiusDeg]  * factor)];
			[plaid setSigmaDeg:([plaid sigmaDeg]  * factor)];
			break;
		default:
			break;
	}
}

- (void)changeWidth:(float)factor;
{
	switch (stimType) {
		case kBarStimulus:
			[bar setWidthDeg:([bar widthDeg]  * factor)];
			break;
		case kGaborStimulus:
			[gabor setSpatialFreqCPD:([gabor spatialFreqCPD] / factor)];
			break;
		case kDotsStimulus:
			[dots setDensity:([dots density] * factor)];
			[[task stimWindow] lock];
			[dots makeMovie:5000];
			[[task stimWindow] unlock];
			break;
		case kPlaidStimulus:
			[plaid setSpatialFreqCPD0:[plaid spatialFreqCPD0] / factor];
			[plaid setSpatialFreqCPD1:[plaid spatialFreqCPD1] / factor];
			break;
		default:
			break;
	}
}

- (void) dealloc;
{
	NSString *key;
	NSEnumerator *enumerator = [keys objectEnumerator];
	
	while ((key = [enumerator nextObject]) != nil) {
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self 
				forKeyPath:[NSString stringWithFormat:@"values.%@", key]];
	}
	[keys release];
	[bar release];
	[gabor release];
	[dots release];
	[plaid release];
	[fixSpot release];
	[[task monitorController] removeMonitorWithID:RFMonitorIDString];
    [super dealloc];
}

- (void)doStimSettings;
{
	switch (stimType) {
		case kBarStimulus:
			[bar runSettingsDialog];
			break;
		case kGaborStimulus:
			[gabor runSettingsDialog];
			break;
		case kDotsStimulus:
			[dots runSettingsDialog];
			break;
		case kPlaidStimulus:
			[plaid runSettingsDialog];
			break;
		default:
			break;
	}
}

- (void)erase;
{
	[[task stimWindow] lock];
	glClearColor(kMidGray, kMidGray, kMidGray, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();
	[[task stimWindow] unlock];
}

- (LLFixTarget *)fixSpot;
{
	return fixSpot;
}

- (id)init;
{
	long index;
	NSEnumerator *enumerator;
	NSString *key, *theKey;
	id object;

	if ((self = [super init]) != nil) {
		monitor = [[[LLIntervalMonitor alloc] initWithID:RFMonitorIDString 
					description:@"Stimulus frame intervals"] autorelease];
		[[task monitorController] addMonitor:monitor];

// For each of the fix spot entries in our settings dialog, set the fix spot
// to the current value and set up to receive report when the value changes.
 
		keys = [[NSArray alloc] initWithObjects:RFDisplayModeKey, RFDoMouseGateKey, 
				RFStimTypeKey, nil];
		enumerator = [keys objectEnumerator];
		while ((key = [enumerator nextObject]) != nil) {
			[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
				forKeyPath:[NSString stringWithFormat:@"values.%@", key]
				options:NSKeyValueObservingOptionNew context:nil];
			object = [[task defaults] objectForKey:key];
			theKey = [LLTextUtil stripPrefixAndDecapitalize:key prefix:@"RF"];
			[self setValue:[[task defaults] objectForKey:key] 
				forKey:[LLTextUtil stripPrefixAndDecapitalize:key prefix:@"RF"]];
		}
		
		for (index = 0; index < kCircleSteps; index++) {
			rotationCos[index] = cos(index * kAngleStep * kRadiansPerDeg);
			rotationSin[index] = sin(index * kAngleStep * kRadiansPerDeg);
		}		
		displays = [[task stimWindow] displays];
		displayIndex = [[task stimWindow] displayIndex];
		[self initializeStimuli];
	} 
	return self;
}

- (void)initializeStimuli;
{
	fixSpot = [[LLFixTarget alloc] init];
	[fixSpot bindValuesToKeysWithPrefix:@"RF"]; 
	bar = [[LLBar alloc] init];					// Create a bar stimulus
	[bar bindValuesToKeysWithPrefix:@"RF"]; 
	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:displays displayIndex:displayIndex];
	[gabor bindValuesToKeysWithPrefix:@"RF"]; 
	dots = [[LLRandomDots alloc] init];			// Create a random dots stimulus
	[dots setDisplays:displays displayIndex:displayIndex];
	[dots bindValuesToKeysWithPrefix:@"RF"]; 
	plaid = [[LLPlaid alloc] init];				// Create a plaid stimulus
	[plaid setDisplays:displays displayIndex:displayIndex];
	[plaid bindValuesToKeysWithPrefix:@"RF"]; 
}

- (LLIntervalMonitor *)monitor;
{
	return monitor;
}

- (BOOL)mouseDown;
{
	if ([[task stimWindow] mouseInside]) {
		mouseButtonDown = YES;
		return YES;
	}
	else {
		return NO;
	}
}

- (BOOL)mouseUp;
{
	if (mouseButtonDown) {
		mouseButtonDown = NO;
		return YES;								// flag that we've handled this event
	}
	return NO;
}

// Respond to changes in the stimulus settings

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
					change:(NSDictionary *)change context:(void *)context {

	NSString *defaultsKey;

	defaultsKey = [keyPath pathExtension];
	[self setValue:[[task defaults] objectForKey:defaultsKey] 
			forKey:[LLTextUtil stripPrefixAndDecapitalize:defaultsKey prefix:@"RF"]];
}

- (void)rotate:(float)deltaDeg;
{
	float absDeltaDeg;
	
	absDeltaDeg = fabs(deltaDeg);
	switch (stimType) {
		case kGaborStimulus:
			[gabor setDirectionDeg:(((long)([gabor directionDeg] / absDeltaDeg)) * absDeltaDeg + deltaDeg)];
			break;
		case kBarStimulus:
			[bar setDirectionDeg:(((long)([bar directionDeg] / absDeltaDeg)) * absDeltaDeg + deltaDeg)];
			break;
		case kDotsStimulus:
			[dots setDirectionDeg:(((long)([dots directionDeg] / absDeltaDeg)) * absDeltaDeg + deltaDeg)];
			[[task stimWindow] lock];
			[dots makeMovie:5000];
			[[task stimWindow] unlock];
			break;
		case kPlaidStimulus:
			[plaid setDirectionDeg0:(((long)([plaid directionDeg0] / absDeltaDeg)) * absDeltaDeg + deltaDeg)];
			[plaid setDirectionDeg1:(((long)([plaid directionDeg1] / absDeltaDeg)) * absDeltaDeg + deltaDeg)];
			break;
	}
}

- (void)startStimulus;
{
	if (!stimulusOn) {
		stopStimulus = NO;
	   [NSThread detachNewThreadSelector:@selector(stimulate) toTarget:self withObject:nil];
	}
}

- (void)stimulate;
{
	long index, startGridDeg, stopGridDeg, gridDeg;
	float gridSpacingDeg, lineLength;
	BOOL modeValid,mouseValid;
    NSAutoreleasePool *threadPool;
	NSPoint stimCenterDeg;
	NSRect stimRectDeg;
 	Rect shieldRect = {-500, -500, 500, 500};
	NSRect bounds;
    NSDate *nextRelease;
	long frame = 0;
	BOOL cursorHidden = NO;

    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	nextRelease = [NSDate dateWithTimeIntervalSinceNow:kAutoreleaseIntS];
	stimulusOn = YES;
	
	if ([[task stimWindow] fullscreen]) {
		bounds = [displays displayBounds:displayIndex];
		shieldRect.top = NSMaxY(bounds);
		shieldRect.left = NSMinX(bounds);
		shieldRect.bottom = NSMinY(bounds);
		shieldRect.right = NSMaxX(bounds);
//		ShieldCursor(&shieldRect, shieldPoint);
	}

// Set up the calibration, including the offset then present the stimulus sequence

 	[gabor setTemporalModulation:kDrifting];
	[gabor setTemporalModulationParam:kSPhase];

// We better have a dots movie ready to go in case someone switches from something else to dots midstimulus

//	if (stimType == kDotsStimulus) {
		[[task stimWindow] lock];
		[dots makeMovie:5000];
		[[task stimWindow] unlock];
//	}
	[monitor reset]; 
    while (!stopStimulus) {
	
// If the cursor has moved onto or off of the display, update its visibility

		if (!cursorHidden && [[task stimWindow] mouseInside]) {
			CGDisplayHideCursor(kCGDirectMainDisplay);
			cursorHidden = YES;
		}
		else if (cursorHidden && ![[task stimWindow] mouseInside]) {
			CGDisplayShowCursor(kCGDirectMainDisplay);
			cursorHidden = NO;
		}
		[[task stimWindow] lock];
		[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
		[[task stimWindow] scaleDisplay];
		stimCenterDeg = [[task stimWindow] mouseLocationDeg];
		glClearColor(kMidGray, kMidGray, kMidGray, 0);
		glClear(GL_COLOR_BUFFER_BIT);

// Display the grid

		if ([[task defaults] boolForKey:RFDoGridKey]) {
			stimRectDeg = [[task stimWindow] displayRectDeg];
			gridSpacingDeg = [[task defaults] floatForKey:RFGridSpacingDegKey];
			glPushMatrix();
			glColor3f(kGridGray, kGridGray, kGridGray);
			glLineWidth(1.0);
			switch ([[task defaults] boolForKey:RFDisplayUnitsKey]) {
			case kAzimuthElevation:
				glBegin(GL_LINES);
				startGridDeg = (long)(NSMinX(stimRectDeg) / gridSpacingDeg) * gridSpacingDeg;
				stopGridDeg = (long)(NSMaxX(stimRectDeg) / gridSpacingDeg) * gridSpacingDeg;
				for (gridDeg = startGridDeg; gridDeg <= stopGridDeg; gridDeg += gridSpacingDeg) {
					glVertex2f(gridDeg, NSMinY(stimRectDeg));
					glVertex2f(gridDeg, NSMaxY(stimRectDeg));
				}
				startGridDeg = (long)(NSMinY(stimRectDeg) / gridSpacingDeg) * gridSpacingDeg;
				stopGridDeg = (long)(NSMaxY(stimRectDeg) / gridSpacingDeg) * gridSpacingDeg;
				for (gridDeg = startGridDeg; gridDeg <= stopGridDeg; gridDeg += gridSpacingDeg) {
					glVertex2f(NSMinX(stimRectDeg), gridDeg);
					glVertex2f(NSMaxX(stimRectDeg), gridDeg);
				}
				glEnd();
				break;
			case kEccentricityAngle:
				lineLength = 2.0 * NSWidth(stimRectDeg);
				for (gridDeg = 30; gridDeg < 360; gridDeg += 30) {
					glBegin(GL_LINES);
					glVertex2f(0, 0);
					glVertex2f(lineLength * cos(gridDeg * kRadiansPerDeg), 
								lineLength * sin(gridDeg * kRadiansPerDeg));
					glEnd();
				}
				stopGridDeg = MAX(fabs(NSMaxY(stimRectDeg)), fabs(NSMinY(stimRectDeg)));
				stopGridDeg = MAX(stopGridDeg, fabs(NSMinX(stimRectDeg)));
				stopGridDeg = MAX(stopGridDeg, fabs(NSMaxX(stimRectDeg))) * 1.5;
				stopGridDeg = (long)(stopGridDeg / gridSpacingDeg) * gridSpacingDeg;
				for (gridDeg = gridSpacingDeg; gridDeg <= stopGridDeg; gridDeg += gridSpacingDeg) {
					glBegin(GL_LINE_LOOP);
					for (index = 0; index < kCircleSteps; index++) {
						glVertex2f(rotationCos[index] * gridDeg, rotationSin[index] * gridDeg);
					}
					glEnd();
				}
				break;
			}
			glLineWidth(2.0);
			glBegin(GL_LINES);
			glVertex2f(0, NSMinY(stimRectDeg));
			glVertex2f(0, NSMaxY(stimRectDeg));
			glVertex2f(NSMinX(stimRectDeg), 0);
			glVertex2f(NSMaxX(stimRectDeg), 0);
			glEnd();
			glLineWidth(1.0);
			glPopMatrix();
		}
		
// Only display if we are in the correct behavioral state and mouse button enabling is correct.

		modeValid = (behaviorMode >= displayMode);
		mouseValid = (mouseButtonDown || !doMouseGate);
		if (modeValid && mouseValid) {
			switch (stimType) {
			case kGaborStimulus:
				[gabor directSetAzimuthDeg:stimCenterDeg.x elevationDeg:stimCenterDeg.y];
				[gabor setFrame:[NSNumber numberWithLong:frame]];
				[gabor draw];
				break;
			case kBarStimulus:
				[bar directSetAzimuthDeg:stimCenterDeg.x elevationDeg:stimCenterDeg.y];
				[bar draw];
				break;
			case kDotsStimulus:
				[dots directSetAzimuthDeg:stimCenterDeg.x elevationDeg:stimCenterDeg.y];
				[dots setFrame:[NSNumber numberWithLong:(frame % [dots movieFrames])]];
				[dots draw];
				break;
			case kPlaidStimulus:
				[plaid directSetAzimuthDeg:stimCenterDeg.x elevationDeg:stimCenterDeg.y];
				[plaid setFrame:[NSNumber numberWithLong:frame]];
				[plaid draw];
				break;
				default:
				break;
			}
		}
		[fixSpot draw];
        [[NSOpenGLContext currentContext] flushBuffer];
		[[task stimWindow] unlock];
        glFinish();
        [monitor recordEvent];
		frame++;
//        if ([nextRelease timeIntervalSinceNow] < 0.0) {
//            [monitor reset];
//            [threadPool release];
//            threadPool = [[NSAutoreleasePool alloc] init];
//            nextRelease = [NSDate dateWithTimeIntervalSinceNow:kAutoreleaseIntS];
//        }
    }

    [monitor reset];

    // Clear the display and leave the back buffer cleared

	[[task stimWindow] lock];
    glClear(GL_COLOR_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();
	[[task stimWindow] unlock];
	[[task dataDoc] putEvent:@"stimulusOff" withData:&frame];

// The temporal counterphase might have changed some settings.  We restore these here.

	if (cursorHidden) {
		CGDisplayShowCursor(kCGDirectMainDisplay);
	}
	stimulusOn = NO;
    [threadPool release];
}

- (BOOL)stimulusOn;
{
	return stimulusOn;
}

- (void)stopStimulus {
	
	if (stimulusOn) {
		stopStimulus = YES;
	}
}

@end
